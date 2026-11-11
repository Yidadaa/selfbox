import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/repositories/message_repository.dart';
import 'package:selfbox/features/memory/domain/repositories/memory_repository.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/repositories/ai_settings_repository.dart';

typedef ScreenshotEnv = ({
  AppPaths? paths,
  MessageRepository? messages,
  MemoryRepository? memory,
  AiSettingsRepository? settings,
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

  static ScreenshotEnv _none() => (
    paths: null,
    messages: null,
    memory: null,
    settings: null,
    overrides: const [],
  );
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
    memory: null,
    settings: null,
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

final _memorySeed = FakeMemoryRepository(
  seed: {
    'user/profile.md': [
      '# 个人档案',
      '',
      '- 称呼：yda',
      '- 城市：上海',
      '- 职业：软件工程师',
    ].join('\n'),
    'user/prefer.md': ['# 偏好', '', '- 咖啡：拿铁，少糖', '- 周末：爬山、摄影'].join('\n'),
    'topic/weekly-report.md': [
      '# 周报',
      '',
      '每周五前提交，抄送团队。',
      '',
      '## 进行中',
      '',
      '- [x] 回复客户邮件',
      '- [ ] 季度复盘（下周一前）',
      '',
      '> 上次提到希望周报更简短。',
    ].join('\n'),
    'topic/hiking.md': ['# 爬山计划', '', '- 候选：天目山、莫干山', '- 关注天气'].join('\n'),
  },
);

ScreenshotEnv _memory() => (
  paths: null,
  messages: null,
  memory: _memorySeed,
  settings: null,
  overrides: const [],
);

ScreenshotEnv _settings() => (
  paths: null,
  messages: null,
  memory: null,
  settings: FakeAiSettingsRepository(
    settings: const AiSettings(
      providers: [
        ProviderConfig(
          id: 'p1',
          name: 'OpenAI',
          format: ApiFormat.responses,
          baseUrl: 'https://api.openai.com/v1',
        ),
        ProviderConfig(
          id: 'p2',
          name: 'Anthropic',
          format: ApiFormat.messages,
          baseUrl: 'https://api.anthropic.com/v1',
        ),
      ],
      models: [
        ModelConfig(providerId: 'p1', modelId: 'gpt-5.5', enabled: true),
        ModelConfig(providerId: 'p1', modelId: 'gpt-5.5-mini'),
        ModelConfig(providerId: 'p1', modelId: 'gpt-image-2'),
        ModelConfig(
          providerId: 'p2',
          modelId: 'claude-opus-5-5',
          enabled: true,
        ),
      ],
      activeModel: ModelRef(providerId: 'p2', modelId: 'claude-opus-5-5'),
    ),
    apiKeys: {'p1': 'k', 'p2': 'k'},
  ),
  overrides: const [],
);

final screenshotFixtures = <ScreenshotFixture>[
  const ScreenshotFixture(name: 'chat_empty', location: '/chat'),
  const ScreenshotFixture(
    name: 'chat_history',
    location: '/chat',
    env: _chatWithHistory,
  ),
  const ScreenshotFixture(name: 'memory_empty', location: '/memory'),
  const ScreenshotFixture(
    name: 'memory_list',
    location: '/memory',
    env: _memory,
  ),
  const ScreenshotFixture(
    name: 'memory_file',
    location: '/memory/file?path=topic%2Fweekly-report.md',
    env: _memory,
  ),
  const ScreenshotFixture(name: 'me', location: '/me', env: _settings),
  const ScreenshotFixture(
    name: 'provider',
    location: '/me/provider?id=p1',
    env: _settings,
  ),
  const ScreenshotFixture(
    name: 'model',
    location: '/me/model?provider=p1&model=gpt-5.5',
    env: _settings,
  ),
];
