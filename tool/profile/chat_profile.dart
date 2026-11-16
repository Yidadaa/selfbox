import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/app.dart';
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/main.dart' as production;

import 'long_chat_fixture.dart';
import 'scene_probe.dart';

Future<void> main() async {
  if (!kProfileMode) throw StateError('Run this entrypoint in profile mode.');
  await production.main();
  final frames = <FrameTiming>[];
  final scenes = <Map<String, Object?>>[];
  WidgetsBinding.instance.addTimingsCallback(frames.addAll);
  developer.registerExtension('ext.selfbox.profile', (_, parameters) async {
    final container = _container();
    final action = parameters['action'];
    final preferences = container.read(
      appPreferencesControllerProvider.notifier,
    );
    switch (action) {
      case 'console':
        final talker = container.read(talkerProvider);
        talker.configure(
          settings: talker.settings.copyWith(
            useConsoleLogs: parameters['value'] != 'false',
          ),
        );
      case 'prepare-long':
        await prepareLongChat(container);
        await preferences.completeOnboarding();
        await preferences.setTheme(AppThemeChoice.dark);
        await preferences.setLanguage(AppLanguageChoice.zhCn);
        await preferences.setRenderQuality(AppRenderQuality.premium);
        await preferences.setAnimationsEnabled(true);
        if (!container.read(composerControllerProvider).aiMode) {
          container.read(composerControllerProvider.notifier).toggleAiMode();
        }
      case 'inspect':
        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            ...inspectScene(),
            'quality': container
                .read(appPreferencesControllerProvider)
                .renderQuality
                .name,
            'animations': container
                .read(appPreferencesControllerProvider)
                .animationsEnabled,
            'messageCount':
                (await container
                        .read(messageRepositoryProvider)
                        .latest(10000)
                        .run())
                    .getOrElse((_) => [])
                    .length,
          }),
        );
      case 'focus':
        _editor().focusNode.requestFocus();
      case 'blur':
        _editor().focusNode.unfocus();
      case 'prepare':
        final repository = container.read(messageRepositoryProvider);
        final existing = await repository.latest(1).run();
        if (existing.isLeft()) throw StateError('Cannot inspect fixture store');
        if (existing
            .getOrElse((_) => [])
            .any((message) => !message.text.contains('Profile fixture '))) {
          throw StateError(
            'Use a dedicated emulator with an empty fixture store',
          );
        }
        if (existing.getOrElse((_) => []).isEmpty) {
          for (var index = 0; index < 240; index++) {
            final added = await repository
                .add(
                  MessageDraft(
                    author: index.isEven ? MessageAuthor.me : MessageAuthor.ai,
                    text: index.isEven
                        ? 'Profile fixture $index：记录今天的工作与计划。保持玻璃效果和交互。'
                        : '### Profile fixture $index\n\n这是一条用于渲染性能对照的回答。'
                              '\n\n- **重点**：保持视觉效果\n- 检查滚动与输入\n\n'
                              '> 同一设备、同一数据、同一场景。\n\n'
                              '行内代码 `final value = 42;` 与普通段落。',
                    askedAi: index.isEven,
                  ),
                )
                .run();
            if (added.isLeft()) throw StateError('Fixture insertion failed');
          }
        }
        await preferences.completeOnboarding();
        await preferences.setTheme(AppThemeChoice.dark);
        await preferences.setLanguage(AppLanguageChoice.zhCn);
        await preferences.setRenderQuality(AppRenderQuality.standard);
        final composer = container.read(composerControllerProvider);
        if (!composer.aiMode) {
          container.read(composerControllerProvider.notifier).toggleAiMode();
        }
      case 'quality':
        await preferences.setRenderQuality(
          AppRenderQuality.values.byName(parameters['value']!),
        );
      case 'theme':
        await preferences.setTheme(
          AppThemeChoice.values.byName(parameters['value']!),
        );
      case 'reset':
        FocusManager.instance.primaryFocus?.unfocus();
        container.read(chatScrollControllerProvider).jumpTo(0);
      case 'keyboard':
        final editor = _editor();
        for (var pass = 0; pass < 8; pass++) {
          editor.focusNode.requestFocus();
          await Future<void>.delayed(const Duration(milliseconds: 1000));
          scenes.add({'phase': 'open', ...inspectScene()});
          editor.focusNode.unfocus();
          await Future<void>.delayed(const Duration(milliseconds: 1000));
          scenes.add({'phase': 'closed', ...inspectScene()});
        }
      case 'typing':
        final editor = _editor();
        editor.focusNode.requestFocus();
        await Future<void>.delayed(const Duration(seconds: 1));
        const draft = 'Profile 输入测试，多行自动换行，不发送网络请求。';
        for (var pass = 0; pass < 5; pass++) {
          for (var length = 1; length <= draft.length; length++) {
            final text = draft.substring(0, length);
            editor.controller.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
            container.read(composerControllerProvider.notifier).setText(text);
            await Future<void>.delayed(const Duration(milliseconds: 60));
          }
          editor.controller.clear();
          container.read(composerControllerProvider.notifier).setText('');
        }
        editor.focusNode.unfocus();
      case 'idle':
        await Future<void>.delayed(const Duration(seconds: 5));
      case 'start':
        frames.clear();
        scenes.clear();
      case 'long-scroll':
      case 'fast-scroll':
        final scroll = container.read(chatScrollControllerProvider);
        final seconds = action == 'fast-scroll' ? 1 : 3;
        for (var page = 1; page <= 10; page++) {
          await scroll.animateTo(
            (page * 2400).clamp(0, scroll.position.maxScrollExtent).toDouble(),
            duration: Duration(seconds: seconds),
            curve: Curves.linear,
          );
          scenes.add({
            'phase': 'scroll',
            'offset': scroll.offset,
            ...inspectScene(),
          });
        }
        await scroll.animateTo(
          0,
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
        );
      case 'scroll':
        final scroll = container.read(chatScrollControllerProvider);
        for (var pass = 0; pass < 4; pass++) {
          await scroll.animateTo(
            2400,
            duration: const Duration(seconds: 3),
            curve: Curves.linear,
          );
          await scroll.animateTo(
            0,
            duration: const Duration(seconds: 3),
            curve: Curves.linear,
          );
        }
      case 'stop':
        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            'scenes': scenes,
            'frames': [
              for (final frame in frames)
                {
                  'buildUs': frame.buildDuration.inMicroseconds,
                  'rasterUs': frame.rasterDuration.inMicroseconds,
                  'totalUs': frame.totalSpan.inMicroseconds,
                  'vsyncUs': frame.timestampInMicroseconds(
                    FramePhase.vsyncStart,
                  ),
                },
            ],
            'refreshRate': WidgetsBinding
                .instance
                .platformDispatcher
                .views
                .first
                .display
                .refreshRate,
            'size': WidgetsBinding
                .instance
                .platformDispatcher
                .views
                .first
                .physicalSize
                .toString(),
          }),
        );
      default:
        throw ArgumentError.value(action, 'action');
    }
    return developer.ServiceExtensionResponse.result(jsonEncode({'ok': true}));
  });
}

EditableText _editor() {
  EditableText? result;
  void visit(Element element) {
    if (element.widget case final EditableText editor) result = editor;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  return result ?? (throw StateError('Editor is not mounted'));
}

ProviderContainer _container() {
  ProviderContainer? result;
  void visit(Element element) {
    if (element.widget is SelfboxApp) {
      result = ProviderScope.containerOf(element, listen: false);
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  return result ?? (throw StateError('App is not mounted'));
}
