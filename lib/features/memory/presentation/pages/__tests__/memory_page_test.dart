import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/widgets/empty_state.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_editor_page.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_file_page.dart';
import 'package:selfbox/features/memory/presentation/providers/memory_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

Future<void> _openMemoryTab(
  WidgetTester tester,
  FakeMemoryRepository memory,
) async {
  final container = await tester.pumpApp(memory: memory);
  container.read(appRouterProvider).go('/memory');
  await tester.pumpAndSettle();
}

void main() {
  group('MemoryPage', () {
    testWidgets('offers creation without an empty-state card', (tester) async {
      await _openMemoryTab(tester, FakeMemoryRepository());
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byKey(const ValueKey('add-memory')), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(t.memory.add)).style,
        Theme.of(tester.element(find.text(t.memory.add))).textTheme.titleSmall,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('add-memory'))).bottom,
        lessThan(tester.getRect(find.byType(AppDockTabs)).top),
      );
    });

    testWidgets('a failed memory load shows retry instead of an empty label', (
      tester,
    ) async {
      var attempts = 0;
      final container = await tester.pumpApp(
        overrides: [
          memoryFoldersProvider.overrideWith(
            (ref) => attempts++ == 0
                ? Stream<List<MemoryFolder>>.error(StateError('unavailable'))
                : Stream.value(<MemoryFolder>[]),
          ),
        ],
      );
      container.read(appRouterProvider).go('/memory');
      await tester.pumpAndSettle();
      expect(find.text(t.common.loadFailed), findsOneWidget);
      expect(find.text(t.memory.add), findsOneWidget);
      await tester.tap(find.text(t.common.retry));
      await tester.pumpAndSettle();
      expect(find.text(t.common.loadFailed), findsNothing);
      expect(find.byKey(const ValueKey('add-memory')), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'editor uses readable text and stays usable with a keyboard in $brightness',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final memory = FakeMemoryRepository(
            seed: {'user.md': '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n'},
          );
          final container = await tester.pumpApp(
            memory: memory,
            locale: AppLocale.zhCn,
          );
          container.read(appRouterProvider).go('/memory/edit?path=user.md');
          await tester.pumpAndSettle();

          final editor = tester.widget<SmoothMarkdownEditor>(
            find.byType(SmoothMarkdownEditor),
          );
          expect(editor.textStyle?.fontFamily, isNot('monospace'));
          expect(
            editor.textStyle?.color,
            Theme.of(tester.element(find.byType(SmoothMarkdownEditor)))
                .textTheme
                .bodyLarge
                ?.color,
          );

          tester.view.physicalSize = const Size(320 * 3, 844 * 3);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(t.common.save),
            200,
            scrollable: find
                .descendant(
                  of: find.byType(MemoryEditorPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.text(t.common.save)).bottom,
            lessThanOrEqualTo(844 - 300),
          );
        },
      );
    }

    testWidgets('creates a memory from a file name and Markdown content', (
      tester,
    ) async {
      final memory = FakeMemoryRepository();
      await _openMemoryTab(tester, memory);
      await tester.tap(find.byKey(const ValueKey('add-memory')));
      await tester.pumpAndSettle();
      expect(find.byType(MemoryEditorPage), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, 'travel.md');
      await tester.enterText(find.byType(EditableText).last, '# Travel\nIdeas');
      await tester.ensureVisible(find.text(t.common.save));
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();
      expect(memory.contentOf('travel.md'), '# Travel\nIdeas\n');
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('lists files under folder headers with their titles', (
      tester,
    ) async {
      await _openMemoryTab(
        tester,
        FakeMemoryRepository(
          seed: {
            'user/profile.md': '# Profile\n- city: Shanghai\n',
            'topic/hiking.md': '# Hiking plans\n',
            'inbox.md': 'loose note\n',
          },
        ),
      );

      expect(find.byType(GlassGroupedSection), findsNWidgets(3));
      expect(find.text(t.memory.rootFolder), findsOneWidget);
      expect(find.text('topic'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Hiking plans'), findsOneWidget);
      expect(find.text('inbox'), findsOneWidget);
    });

    testWidgets('updates live when the agent writes a file', (tester) async {
      final memory = FakeMemoryRepository();
      await _openMemoryTab(tester, memory);

      await memory.create(_path('topic/new.md'), '# Fresh topic\n').run();
      await tester.pumpAndSettle();

      expect(find.text('Fresh topic'), findsOneWidget);
    });

    testWidgets('opens a file as rendered markdown without the tab bar', (
      tester,
    ) async {
      await _openMemoryTab(
        tester,
        FakeMemoryRepository(
          seed: {'user/profile.md': '# Profile\n\n- **City**: Shanghai\n'},
        ),
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(MemoryFilePage), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsOneWidget);
      expect(find.byType(AppDockTabs), findsNothing);
      await tester.tap(find.bySemanticsLabel(t.memory.edit));
      await tester.pumpAndSettle();
      expect(find.byType(MemoryEditorPage), findsOneWidget);
      await tester.enterText(find.byType(EditableText).last, '# Updated\n');
      await tester.ensureVisible(find.text(t.common.save));
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();
      expect(find.byType(MemoryFilePage), findsOneWidget);
      expect(find.text('Updated', findRichText: true), findsWidgets);
    });

    testWidgets('an external edit cannot be overwritten by an open editor', (
      tester,
    ) async {
      final memory = FakeMemoryRepository(seed: {'user.md': 'Original\n'});
      final container = await tester.pumpApp(memory: memory);
      container.read(appRouterProvider).go('/memory/edit?path=user.md');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).last, 'My draft');

      await memory
          .replace(_path('user.md'), 'AI update', expectedContent: 'Original\n')
          .run();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.common.save));
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(memory.contentOf('user.md'), 'AI update\n');
      expect(find.text(t.memory.changed), findsOneWidget);
      expect(find.byType(MemoryEditorPage), findsOneWidget);
    });

    testWidgets('deleting from the file page removes it and goes back', (
      tester,
    ) async {
      final memory = FakeMemoryRepository(
        seed: {'user/profile.md': '# Profile\n'},
      );
      await _openMemoryTab(tester, memory);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(t.memory.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();

      expect(memory.contentOf('user/profile.md'), isNull);
      expect(find.byType(MemoryFilePage), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('an unknown file shows the missing state', (tester) async {
      final container = await tester.pumpApp();
      container.read(appRouterProvider).go('/memory/file?path=user%2Fnope.md');
      await tester.pumpAndSettle();

      expect(find.text(t.memory.missing), findsOneWidget);
      expect(find.byIcon(Icons.find_in_page_outlined), findsOneWidget);
    });
  });
}

MemoryPath _path(String raw) =>
    MemoryPath.parse(raw).getOrElse((f) => fail('$f'));
