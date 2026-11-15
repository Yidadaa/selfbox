import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/profile_page.dart';
import 'package:selfbox/features/settings/presentation/providers/settings_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'settings_test_support.dart';

void main() {
  testWidgets('loading uses the editor layout and load errors can retry', (
    tester,
  ) async {
    var failed = true;
    final container = await tester.pumpPage(
      const ProfilePage(),
      settle: false,
      overrides: [
        aiSettingsProvider.overrideWith(
          (ref) => failed
              ? Stream<AiSettings>.error(StateError('unavailable'))
              : Stream.value(const AiSettings(customPrompt: 'Recovered')),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(t.common.retry), findsOneWidget);
    failed = false;
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      'Recovered',
    );
    expect(container.read(aiSettingsProvider).hasValue, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
    final loadingContainer = await tester.pumpPage(
      const ProfilePage(),
      settle: false,
      overrides: [
        aiSettingsProvider.overrideWith(
          (ref) => const Stream<AiSettings>.empty(),
        ),
      ],
    );
    expect(
      find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
      findsWidgets,
    );
    expect(find.byType(EditableText), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox.shrink());
    loadingContainer.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
  for (final locale in AppLocale.values) {
    testWidgets('custom prompt entry edits, persists and clears in $locale', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(customPrompt: 'Old prompt'),
      );
      final container = await tester.pumpApp(
        settings: settings,
        locale: locale,
      );
      container.read(appRouterProvider).go('/me/providers');
      await tester.pumpAndSettle();
      expect(find.text('Custom instructions'), findsNothing);
      expect(find.text('自定义提示词'), findsNothing);
      container.read(appRouterProvider).go('/me/profile');
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'Old prompt',
      );
      await tester.enterText(
        find.byType(EditableText).last,
        '中文 instructions\nKeep details',
      );
      await tester.tap(find.text(t.common.save));
      await settleSettingsToasts(tester);
      expect(settings.current.customPrompt, '中文 instructions\nKeep details');
      container.read(appRouterProvider).go('/me/profile');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        '中文 instructions\nKeep details',
      );
      await tester.enterText(find.byType(EditableText).last, '');
      await tester.tap(find.text(t.common.save));
      await settleSettingsToasts(tester);
      expect(settings.current.customPrompt, '');
    });
  }
  testWidgets('failed save preserves draft and retries', (tester) async {
    final settings = _FailingSettings();
    await openSettingsPage(tester, '/me/profile', settings: settings);
    await tester.enterText(find.byType(EditableText).last, 'Keep this draft');
    await tester.tap(find.text(t.common.save));
    await settleSettingsToasts(tester);
    expect(settings.current.customPrompt, '');
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      'Keep this draft',
    );
    settings.failSave = false;
    await tester.tap(find.text(t.common.save));
    await settleSettingsToasts(tester);
    expect(settings.current.customPrompt, 'Keep this draft');
  });
  testWidgets('narrow keyboard layout scrolls to save and validates length', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository();
    await openSettingsPage(tester, '/me/profile', settings: settings);
    tester.view.physicalSize = const Size(280 * 3, 640 * 3);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260 * 3);
    await tester.enterText(
      find.byType(EditableText).last,
      'x' * (AiSettingsSchema.maxCustomPromptLength + 1),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.text(t.common.save)).dy,
      lessThan(640 - 260),
    );
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.text(t.forms.tooLong), findsOneWidget);
    expect(settings.current.customPrompt, '');
    expect(tester.takeException(), isNull);
  });
}

class _FailingSettings extends FakeAiSettingsRepository {
  bool failSave = true;
  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) => failSave
      ? TaskEither.left(const AppFailure.database(message: 'disk full'))
      : super.save(settings);
}
