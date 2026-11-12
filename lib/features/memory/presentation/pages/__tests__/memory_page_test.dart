import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';
import 'package:selfbox/features/memory/presentation/pages/memory_file_page.dart';
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
    testWidgets('shows the empty state without memories', (tester) async {
      await _openMemoryTab(tester, FakeMemoryRepository());
      expect(find.text(t.memory.empty), findsOneWidget);
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
      expect(find.text(t.memory.empty), findsOneWidget);
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
