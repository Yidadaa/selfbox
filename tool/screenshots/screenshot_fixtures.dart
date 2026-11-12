import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/repositories/message_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
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
    this.animated = false,
  });

  /// Something animates forever (AI status); pump instead of settling.
  final bool animated;

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

ScreenshotEnv _chatWithHistory({bool includeReply = true}) {
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
        m(
          5,
          _at(12, 9, 24),
          '',
          images: ['media/aurora.png', 'media/aurora.png', 'media/aurora.png'],
        ),
        m(6, _at(12, 9, 30), '我这周都记了哪些待办？', askedAi: true),
        if (includeReply)
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

ScreenshotEnv _newUserMemory() => (
  paths: null,
  messages: null,
  memory: FakeMemoryRepository(
    seed: {'user.md': '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n'},
  ),
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

class _FixedAssistant extends AssistantController {
  @override
  AssistantState build() => const AssistantState.working(
    AgentActivity.tool(AgentToolKind.searchMessages),
  );
}

ScreenshotEnv _chatAsking() {
  final base = _chatWithHistory(includeReply: false);
  return (
    paths: base.paths,
    messages: base.messages,
    memory: null,
    settings: null,
    overrides: [assistantControllerProvider.overrideWith(_FixedAssistant.new)],
  );
}

final screenshotFixtures = <ScreenshotFixture>[
  ScreenshotFixture(
    name: 'chat_review',
    location: '/chat',
    env: () {
      final base = _chatWithHistory();
      return (
        paths: base.paths,
        messages: FakeMessageRepository(
          seed: [
            Message(
              id: 1,
              createdAt: _at(12, 9, 24),
              author: MessageAuthor.me,
              text: '周末想去这里走走',
              images: const ['media/aurora.png'],
            ),
            Message(
              id: 2,
              createdAt: _at(12, 9, 30),
              author: MessageAuthor.me,
              text: '我这周记了哪些待办？',
              askedAi: true,
            ),
            Message(
              id: 3,
              createdAt: _at(12, 9, 31),
              author: MessageAuthor.ai,
              text: '这周有三件待办：回复客户邮件、提交周报、完成季度复盘。',
            ),
          ],
        ),
        memory: null,
        settings: null,
        overrides: const [],
      );
    },
  ),
  ScreenshotFixture(
    name: 'chat_photo_caption',
    location: '/chat',
    env: () {
      final base = _chatWithHistory();
      return (
        paths: base.paths,
        messages: FakeMessageRepository(
          seed: [
            Message(
              id: 1,
              createdAt: _at(12, 9, 30),
              author: MessageAuthor.me,
              text: '周末想去这里走走',
              images: const ['media/aurora.png'],
              askedAi: true,
            ),
          ],
        ),
        memory: null,
        settings: null,
        overrides: const [],
      );
    },
  ),
  ScreenshotFixture(
    name: 'chat_keyboard',
    location: '/chat',
    env: _chatWithHistory,
    setUp: (tester, _) async {
      await tester.enterText(find.byType(EditableText), '帮我整理一下这周的想法');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();
    },
  ),
  ScreenshotFixture(
    name: 'chat_dark',
    location: '/chat',
    env: _chatWithHistory,
    setUp: (tester, _) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
    },
  ),
  const ScreenshotFixture(name: 'chat_empty', location: '/chat'),
  const ScreenshotFixture(
    name: 'chat_history',
    location: '/chat',
    env: _chatWithHistory,
  ),
  const ScreenshotFixture(
    name: 'chat_ai_pending',
    location: '/chat',
    env: _chatAsking,
    animated: true,
  ),
  const ScreenshotFixture(
    name: 'memory_new_user',
    location: '/memory',
    env: _newUserMemory,
  ),
  const ScreenshotFixture(
    name: 'memory_editor',
    location: '/memory/edit?path=user.md',
    env: _newUserMemory,
  ),
  ScreenshotFixture(
    name: 'memory_editor_dark',
    location: '/memory/edit?path=user.md',
    env: _newUserMemory,
    setUp: (tester, _) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
    },
  ),
  ScreenshotFixture(
    name: 'memory_new_user_dark',
    location: '/memory',
    env: _newUserMemory,
    setUp: (tester, _) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
    },
  ),
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
  const ScreenshotFixture(name: 'profile', location: '/me/profile'),
  const ScreenshotFixture(name: 'storage', location: '/me/storage'),
  const ScreenshotFixture(name: 'about', location: '/me/about'),
  const ScreenshotFixture(name: 'logs', location: '/me/logs'),
  const ScreenshotFixture(
    name: 'providers',
    location: '/me/providers',
    env: _settings,
  ),
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
