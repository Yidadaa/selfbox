import 'dart:typed_data';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/app_failure.dart';
import '../../../memory/domain/models/memory.dart';
import '../../../memory/domain/repositories/memory_repository.dart';
import '../models/message.dart';
import '../repositories/message_repository.dart';

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
  });

  final MessageRepository messages;
  final MemoryRepository memory;
  final ImageReader readImage;
  final bool canViewImages;

  /// Filled by `view_image`, keyed by tool call id.
  final viewedImages = <String, ViewedImage>{};

  static const maxListed = 50;
  static const maxContext = 20;
  static const snippetLength = 300;
  static const maxMessageLength = 4000;
  static const maxMemoryLength = 20000;

  ToolSet build() => {
    'search_messages': _tool(
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
      'List all memory files with their titles.',
      const {},
      (_, _) => _listMemory(),
    ),
    'memory_read': _tool(
      'Read one memory file. Always read a file before patching it.',
      {'path': _string('e.g. "user/profile.md".')},
      _readMemory,
      required: ['path'],
    ),
    'memory_search': _tool(
      'Find lines in memory files containing all keywords.',
      {'keywords': _string('Space-separated words; all must appear.')},
      _searchMemory,
      required: ['keywords'],
    ),
    'memory_create': _tool(
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

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<Object?> _withPath(
    ToolInput input,
    TaskEither<AppFailure, Map<String, Object?>> Function(MemoryPath) run,
  ) => MemoryPath.parse(_str(input['path']) ?? '')
      .match((f) async => _error(_describe(f)), (path) => _answer(run(path)));

  static Future<Object?> _answer(
    TaskEither<AppFailure, Map<String, Object?>> task,
  ) async => (await task.run()).match((f) => _error(_describe(f)), (ok) => ok);

  static Map<String, Object?> _error(String message) => {'error': message};

  static String _describe(AppFailure failure) => switch (failure) {
    ValidationFailure(:final message) ||
    DatabaseFailure(:final message) ||
    NetworkFailure(:final message) => message,
    PermissionFailure(:final permission) => 'permission denied: $permission',
    UnexpectedFailure(:final error) => error.toString(),
  };

  static Map<String, Object?> _messageJson(Message m, {required int maxText}) =>
      {
        'id': m.id,
        'time': _iso(m.createdAt),
        'author': m.author.name,
        'text': _truncate(m.text, maxText),
        if (m.images.isNotEmpty) 'images': m.images.length,
      };

  static String _iso(DateTime t) =>
      t.toLocal().toIso8601String().substring(0, 16).replaceFirst('T', ' ');

  static String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';

  static String? _str(Object? value) => value is String ? value : null;

  static int? _intOf(Object? value) => switch (value) {
    final int v => v,
    final double v when v == v.roundToDouble() => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };

  static DateTime? _date(Object? value, {bool endOfDay = false}) {
    final parsed = DateTime.tryParse(_str(value) ?? '');
    if (parsed == null) return null;
    final dateOnly = (_str(value) ?? '').length <= 10;
    return endOfDay && dateOnly
        ? parsed.add(const Duration(days: 1, microseconds: -1))
        : parsed;
  }

  static String _mediaType(String path) => switch (p.extension(path)) {
    '.png' => 'image/png',
    '.gif' => 'image/gif',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    _ => 'image/jpeg',
  };

  static Map<String, Object?> _string(String description) => {
    'type': 'string',
    'description': description,
  };

  static Map<String, Object?> _int(String description) => {
    'type': 'integer',
    'description': description,
  };

  static Tool<ToolInput, Object?> _tool(
    String description,
    Map<String, Object?> properties,
    Future<Object?> Function(ToolInput input, String toolCallId) run, {
    List<String> required = const [],
  }) => tool<ToolInput, Object?>(
    description: description,
    inputSchema: Schema<ToolInput>(
      jsonSchema: {
        'type': 'object',
        'properties': properties,
        'required': required,
        'additionalProperties': false,
      },
      fromJson: Map<String, Object?>.of,
    ),
    execute: (input, options) => run(input, options.toolCallId ?? ''),
  );
}
