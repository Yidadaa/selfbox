import 'dart:typed_data';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/app_failure.dart';
import '../../../memory/domain/models/memory.dart';
import '../../../memory/domain/repositories/memory_repository.dart';
import '../models/message.dart';
import '../repositories/message_repository.dart';

part 'agent_tool_support.dart';

typedef ToolInput = Map<String, Object?>;

/// An image the agent asked to see; attached to the conversation right after
/// the `view_image` result (tool results themselves carry text only).
typedef ViewedImage = ({Uint8List bytes, String mediaType});

/// Loads a stored message image by its root-relative path.
typedef ImageReader = TaskEither<AppFailure, Uint8List> Function(String path);

/// Tools the assistant uses to look through the user's notes and maintain
/// its markdown memory.
///
/// Every tool answers with a JSON-able map. Failures come back as
/// `{"error": ...}` so the model can read them and correct itself instead of
/// the run aborting.
class AgentTools {
  AgentTools({
    required this.messages,
    required this.memory,
    required this.readImage,
    required this.canViewImages,
    this.onResult,
  });

  final MessageRepository messages;
  final MemoryRepository memory;
  final ImageReader readImage;
  final bool canViewImages;
  final void Function(String toolName, bool succeeded)? onResult;

  /// Filled by `view_image`, keyed by tool call id.
  final viewedImages = <String, ViewedImage>{};

  static const maxListed = 50;
  static const maxContext = 20;
  static const snippetLength = 300;
  static const maxMessageLength = 4000;
  static const maxMemoryLength = 20000;

  ToolSet build() => {
    'search_messages': _tool(
      'search_messages',
      'Search the user\'s chat notes, newest first. All keywords must match '
          '(case-insensitive substring). Omit keywords to list by time range. '
          'Use read_messages to see full text and surrounding context.',
      {
        'keywords': _string('Space-separated words; all must appear.'),
        'from': _string('Inclusive start, ISO 8601 date or date-time.'),
        'to': _string('Inclusive end, ISO 8601 date or date-time.'),
        'author': {
          'type': 'string',
          'enum': ['me', 'ai'],
          'description': '"me" for the user\'s notes, "ai" for your replies.',
        },
        'limit': _int('Max results (1-$maxListed, default 20).'),
      },
      _searchMessages,
    ),
    'read_messages': _tool(
      'read_messages',
      'Read a message in full with the messages around it, oldest first.',
      {
        'id': _int('Message id from search results or history.'),
        'before': _int(
          'Earlier messages to include (0-$maxContext, default 5).',
        ),
        'after': _int('Later messages to include (0-$maxContext, default 5).'),
      },
      _readMessages,
      required: ['id'],
    ),
    if (canViewImages)
      'view_image': _tool(
        'view_image',
        'Look at an image attached to a message. The image is shown to you '
            'right after this call.',
        {
          'message_id': _int('Id of the message holding the image.'),
          'index': _int('Which image of that message, 0-based (default 0).'),
        },
        _viewImage,
        required: ['message_id'],
      ),
    'memory_list': _tool(
      'memory_list',
      'List all memory files with their titles.',
      const {},
      (_, _) => _listMemory(),
    ),
    'memory_read': _tool(
      'memory_read',
      'Read one memory file. Always read a file before patching it.',
      {'path': _string('e.g. "user/profile.md".')},
      _readMemory,
      required: ['path'],
    ),
    'memory_search': _tool(
      'memory_search',
      'Find lines in memory files containing all keywords.',
      {'keywords': _string('Space-separated words; all must appear.')},
      _searchMemory,
      required: ['keywords'],
    ),
    'memory_create': _tool(
      'memory_create',
      'Create a NEW memory file. Fails if it exists; use memory_patch to '
          'change existing files.',
      {
        'path': _string('Lowercase, "/"-separated, ending in .md.'),
        'content': _string('Full markdown content, starting with a # title.'),
      },
      _createMemory,
      required: ['path', 'content'],
    ),
    'memory_patch': _tool(
      'memory_patch',
      'Edit an existing memory file with a unified diff (like `diff -u`). '
          'Hunks start with "@@ ... @@"; context lines start with a space, '
          'removed lines with "-", added lines with "+". Context and removed '
          'lines must match the current file exactly. Never rewrite a whole '
          'file to change part of it.',
      {
        'path': _string('Existing memory file path.'),
        'diff': _string('Unified diff against the current content.'),
      },
      _patchMemory,
      required: ['path', 'diff'],
    ),
    'memory_delete': _tool(
      'memory_delete',
      'Delete a memory file that is obsolete or merged elsewhere.',
      {'path': _string('Existing memory file path.')},
      _deleteMemory,
      required: ['path'],
    ),
  };

  // ── Tool implementations ────────────────────────────────────────────────

  Future<Object?> _searchMessages(ToolInput input, String _) async {
    final from = _date(input['from']);
    final to = _date(input['to'], endOfDay: true);
    final query = MessageQuery(
      keywords: _str(input['keywords']) ?? '',
      from: from,
      to: to,
      author: switch (input['author']) {
        'me' => MessageAuthor.me,
        'ai' => MessageAuthor.ai,
        _ => null,
      },
      limit: (_intOf(input['limit']) ?? 20).clamp(1, maxListed),
    );
    return _answer(
      messages
          .find(query)
          .map(
            (found) => {
              'count': found.length,
              'messages': [
                for (final m in found) _messageJson(m, maxText: snippetLength),
              ],
            },
          ),
    );
  }

  Future<Object?> _readMessages(ToolInput input, String _) async {
    final id = _intOf(input['id']);
    if (id == null) return _error('"id" must be an integer');
    return _answer(
      messages
          .around(
            id,
            before: (_intOf(input['before']) ?? 5).clamp(0, maxContext),
            after: (_intOf(input['after']) ?? 5).clamp(0, maxContext),
          )
          .map(
            (window) => window.isEmpty
                ? {'error': 'no message with id $id'}
                : {
                    'messages': [
                      for (final m in window)
                        _messageJson(m, maxText: maxMessageLength),
                    ],
                  },
          ),
    );
  }

  Future<Object?> _viewImage(ToolInput input, String toolCallId) async {
    final id = _intOf(input['message_id']);
    if (id == null) return _error('"message_id" must be an integer');
    final index = _intOf(input['index']) ?? 0;
    return _answer(
      messages
          .byId(id)
          .flatMap(
            (found) => TaskEither.fromOption(
              found.flatMap(
                (m) => Option.fromNullable(
                  index >= 0 && index < m.images.length
                      ? m.images[index]
                      : null,
                ),
              ),
              () => AppFailure.validation(
                message: 'message $id has no image at index $index',
              ),
            ),
          )
          .flatMap(
            (path) => readImage(path).map((bytes) {
              viewedImages[toolCallId] = (
                bytes: bytes,
                mediaType: _mediaType(path),
              );
              return {'ok': true, 'image': 'message $id, index $index'};
            }),
          ),
    );
  }

  Future<Object?> _listMemory() => _answer(
    memory.list().map(
      (entries) => {
        'files': [
          for (final e in entries)
            {
              'path': e.path.value,
              'title': e.title,
              'updated': _iso(e.updatedAt),
            },
        ],
      },
    ),
  );

  Future<Object?> _readMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .read(path)
        .map(
          (file) => file.match(
            () => {'error': '${path.value} does not exist'},
            (f) => {
              'path': f.path.value,
              'content': _truncate(f.content, maxMemoryLength),
            },
          ),
        ),
  );

  Future<Object?> _searchMemory(ToolInput input, String _) => _answer(
    memory
        .search(_str(input['keywords']) ?? '')
        .map(
          (hits) => {
            'hits': [
              for (final h in hits)
                {'path': h.path.value, 'line': h.line, 'text': h.text},
            ],
          },
        ),
  );

  Future<Object?> _createMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .create(path, _str(input['content']) ?? '')
        .map((f) => {'ok': true, 'path': f.path.value}),
  );

  Future<Object?> _patchMemory(ToolInput input, String _) => _withPath(
    input,
    (path) => memory
        .patch(path, _str(input['diff']) ?? '')
        .map((f) => {'ok': true, 'path': f.path.value, 'content': f.content}),
  );

  Future<Object?> _deleteMemory(ToolInput input, String _) =>
      _withPath(input, (path) => memory.delete(path).map((_) => {'ok': true}));
}
