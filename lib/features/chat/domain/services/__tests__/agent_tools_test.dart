import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/agent_tools.dart';

Message _m(
  int id,
  String text, {
  int hour = 9,
  List<String> images = const [],
}) => Message(
  id: id,
  createdAt: DateTime(2026, 11, id, hour),
  author: MessageAuthor.me,
  text: text,
  images: images,
);

typedef _Env = ({AgentTools tools, FakeMemoryRepository memory});

_Env _env({bool images = true, List<Message> seed = const []}) {
  final memory = FakeMemoryRepository(
    seed: {'user/prefer.md': '# Prefer\n- coffee: latte\n'},
  );
  final tools = AgentTools(
    messages: FakeMessageRepository(seed: seed),
    memory: memory,
    readImage: (path) => path == 'media/a.png'
        ? TaskEither.right(Uint8List.fromList([7, 7]))
        : TaskEither.left(const AppFailure.database(message: 'missing')),
    canViewImages: images,
  );
  return (tools: tools, memory: memory);
}

Future<Map<String, Object?>> _call(
  AgentTools tools,
  String name,
  Map<String, Object?> input, {
  String callId = 'c1',
}) async {
  final tool = tools.build()[name];
  expect(tool, isNotNull, reason: 'tool $name');
  final raw = await tool!.executeDynamic!(
    input,
    ToolExecutionOptions(toolCallId: callId),
  );
  // Round-trip through JSON exactly as the SDK sends results to the model.
  return jsonDecode(jsonEncode(raw)) as Map<String, Object?>;
}

void main() {
  group('AgentTools', () {
    test('exposes the documented tool names', () {
      expect(_env().tools.build().keys, [
        'search_messages',
        'read_messages',
        'view_image',
        'memory_list',
        'memory_read',
        'memory_search',
        'memory_create',
        'memory_patch',
        'memory_delete',
      ]);
    });

    test('omits view_image for models without vision', () {
      expect(_env(images: false).tools.build(), isNot(contains('view_image')));
    });

    test('every tool schema is a closed JSON object', () {
      for (final MapEntry(:key, :value) in _env().tools.build().entries) {
        final schema = value.inputSchema.jsonSchema;
        expect(schema['type'], 'object', reason: key);
        expect(schema['additionalProperties'], isFalse, reason: key);
        expect(value.description, isNotEmpty, reason: key);
      }
    });

    test('search_messages filters by keywords and day range', () async {
      final env = _env(seed: [_m(1, '提交周报'), _m(2, '周末爬山'), _m(3, '周报改好了')]);
      final result = await _call(env.tools, 'search_messages', {
        'keywords': '周报',
        'from': '2026-11-02',
        'to': '2026-11-03',
      });

      final found = result['messages']! as List<Object?>;
      expect(found, hasLength(1));
      expect((found.single! as Map)['id'], 3);
      expect((found.single! as Map)['time'], '2026-11-03 09:00');
    });

    test('search_messages truncates long notes to a snippet', () async {
      final env = _env(seed: [_m(1, 'x' * 1000)]);
      final result = await _call(env.tools, 'search_messages', {});
      final text =
          ((result['messages']! as List).single! as Map)['text']! as String;
      expect(text.length, AgentTools.snippetLength + 1);
    });

    test('read_messages returns the window around a note', () async {
      final env = _env(seed: [for (var i = 1; i <= 5; i++) _m(i, 'n$i')]);
      final result = await _call(env.tools, 'read_messages', {
        'id': 3,
        'before': 1,
        'after': 1,
      });
      expect((result['messages']! as List).map((m) => (m! as Map)['text']), [
        'n2',
        'n3',
        'n4',
      ]);
    });

    test('read_messages reports unknown ids and bad input as errors', () async {
      final env = _env();
      expect(
        (await _call(env.tools, 'read_messages', {'id': 9}))['error'],
        contains('no message'),
      );
      expect(
        (await _call(env.tools, 'read_messages', {'id': 'x'}))['error'],
        contains('integer'),
      );
    });

    test('view_image stores the bytes for the next step', () async {
      final env = _env(
        seed: [
          _m(1, '', images: ['media/a.png']),
        ],
      );
      final result = await _call(env.tools, 'view_image', {
        'message_id': 1,
      }, callId: 'img1');

      expect(result['ok'], isTrue);
      expect(env.tools.viewedImages['img1']?.bytes, [7, 7]);
      expect(env.tools.viewedImages['img1']?.mediaType, 'image/png');
    });

    test('view_image rejects an out-of-range index', () async {
      final env = _env(
        seed: [
          _m(1, '', images: ['media/a.png']),
        ],
      );
      final result = await _call(env.tools, 'view_image', {
        'message_id': 1,
        'index': 3,
      });
      expect(result['error'], contains('no image'));
      expect(env.tools.viewedImages, isEmpty);
    });

    test('memory tools list, read and search', () async {
      final tools = _env().tools;
      final list = await _call(tools, 'memory_list', {});
      expect(((list['files']! as List).single! as Map)['title'], 'Prefer');

      final read = await _call(tools, 'memory_read', {
        'path': 'user/prefer.md',
      });
      expect(read['content'], contains('latte'));

      final hits = await _call(tools, 'memory_search', {'keywords': 'coffee'});
      expect(((hits['hits']! as List).single! as Map)['line'], 2);
    });

    test(
      'memory_create, memory_patch and memory_delete change files',
      () async {
        final env = _env();
        await _call(env.tools, 'memory_create', {
          'path': 'topic/hiking.md',
          'content': '# Hiking\n- 天目山',
        });
        expect(env.memory.contentOf('topic/hiking.md'), '# Hiking\n- 天目山\n');

        final patched = await _call(env.tools, 'memory_patch', {
          'path': 'user/prefer.md',
          'diff': '@@ @@\n-- coffee: latte\n+- coffee: flat white\n',
        });
        expect(patched['ok'], isTrue);
        expect(env.memory.contentOf('user/prefer.md'), contains('flat white'));

        await _call(env.tools, 'memory_delete', {'path': 'topic/hiking.md'});
        expect(env.memory.contentOf('topic/hiking.md'), isNull);
      },
    );

    test(
      'memory_create refuses to overwrite; patch needs exact context',
      () async {
        final env = _env();
        final create = await _call(env.tools, 'memory_create', {
          'path': 'user/prefer.md',
          'content': 'x',
        });
        expect(create['error'], contains('exists'));

        final patch = await _call(env.tools, 'memory_patch', {
          'path': 'user/prefer.md',
          'diff': '@@ @@\n-- tea: green\n+- tea: black\n',
        });
        expect(patch['error'], contains('does not match'));
        expect(env.memory.contentOf('user/prefer.md'), contains('latte'));
      },
    );

    test('memory paths that escape the tree are rejected', () async {
      final result = await _call(_env().tools, 'memory_read', {
        'path': '../../secret.md',
      });
      expect(result['error'], contains('invalid memory path'));
    });
  });
}
