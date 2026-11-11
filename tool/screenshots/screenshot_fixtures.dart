import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/repositories/message_repository.dart';

typedef ScreenshotEnv = ({
  AppPaths? paths,
  MessageRepository? messages,
  List<Override> overrides,
});

class ScreenshotFixture {
  const ScreenshotFixture({
    required this.name,
    required this.location,
    this.env = _none,
    this.setUp,
  });

  final String name;
  final String location;
  final ScreenshotEnv Function() env;
  final Future<void> Function(WidgetTester tester, ProviderContainer container)?
  setUp;

  static ScreenshotEnv _none() =>
      (paths: null, messages: null, overrides: const []);
}

DateTime _at(int day, int hour, int minute) =>
    DateTime(kTestNow.year, kTestNow.month, day, hour, minute);

ScreenshotEnv _chatWithHistory() {
  final root = Directory.systemTemp.createTempSync('selfbox_shot_');
  final media = Directory(p.join(root.path, 'media'))..createSync();
  File('tool/screenshots/assets/aurora.png')
      .copySync(p.join(media.path, 'aurora.png'));
  Message m(
    int id,
    DateTime at,
    String text, {
    MessageAuthor author = MessageAuthor.me,
    List<String> images = const [],
    bool askedAi = false,
  }) => Message(
    id: id,
    createdAt: at,
    author: author,
    text: text,
    images: images,
    askedAi: askedAi,
  );
  return (
    paths: AppPaths(root),
    overrides: const <Override>[],
    messages: FakeMessageRepository(
      seed: [
        m(1, _at(11, 21, 40), '下周一前把季度复盘写完'),
        m(2, _at(12, 8, 32), '记得回复客户邮件 ✉️'),
        m(3, _at(12, 8, 52), '明天要提交周报'),
        m(4, _at(12, 9, 12), '周末想去爬山 🌿，放松一下心情'),
        m(5, _at(12, 9, 24), '', images: ['media/aurora.png']),
        m(6, _at(12, 9, 30), '我这周都记了哪些待办？', askedAi: true),
        m(
          7,
          _at(12, 9, 31),
          '这周你记下了 **3 件待办**：\n\n'
          '- 回复客户邮件\n- 明天提交周报\n- 下周一前完成季度复盘\n\n'
          '周末还计划去爬山，记得看天气。',
          author: MessageAuthor.ai,
        ),
      ],
    ),
  );
}

final screenshotFixtures = <ScreenshotFixture>[
  const ScreenshotFixture(name: 'chat_empty', location: '/chat'),
  const ScreenshotFixture(
    name: 'chat_history',
    location: '/chat',
    env: _chatWithHistory,
  ),
  const ScreenshotFixture(name: 'memory_empty', location: '/memory'),
  const ScreenshotFixture(name: 'me', location: '/me'),
];
