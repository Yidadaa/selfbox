import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/features/chat/presentation/providers/message_search.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'chat_page_test_support.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'search field icon uses neutral theme foreground in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp();
        await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('message-search-input'));
        final icon = tester.widget<AppIcon>(
          find.descendant(
            of: input,
            matching: find.byWidgetPredicate(
              (w) => w is AppIcon && w.icon == AppIcons.search,
            ),
          ),
        );
        expect(icon.color, tester.element(input).glass.foregroundMuted);
      },
    );
  }
  for (final (locale, prompt, emptyLabel) in [
    (AppLocale.en, 'Search your thoughts', 'No messages found'),
    (AppLocale.zhCn, '搜索你的碎碎念', '没有搜索到消息'),
  ]) {
    testWidgets(
      'message search filters notes and shows localized empty states in $locale',
      (tester) async {
        await tester.pumpApp(
          locale: locale,
          messages: FakeMessageRepository(
            seed: [
              testMessage(1, 'weekly report'),
              testMessage(2, 'weekend hike'),
            ],
          ),
        );
        await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
        await tester.pumpAndSettle();
        expect(find.text(prompt), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(prompt),
            matching: find.byType(GlassContainer),
          ),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const ValueKey('message-search-input')),
          'report',
        );
        await tester.pumpAndSettle();
        expect(find.text('weekly report'), findsOneWidget);
        expect(find.text('weekend hike'), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('message-search-input')),
          'missing phrase',
        );
        await tester.pumpAndSettle();
        expect(find.text(t.chat.noSearchResults), findsOneWidget);
        expect(find.text(emptyLabel), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(t.chat.noSearchResults),
            matching: find.byType(GlassContainer),
          ),
          findsNothing,
        );
      },
    );
  }

  testWidgets('message search failures offer a retry action', (tester) async {
    await tester.pumpApp(
      overrides: [
        messageSearchProvider('broken').overrideWith(
          (ref) async =>
              const Left(AppFailure.database(message: 'unavailable')),
        ),
      ],
    );
    await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('message-search-input')),
      'broken',
    );
    await tester.pumpAndSettle();

    expect(find.text(t.settings.errors.generic), findsOneWidget);
    expect(find.text(t.common.retry), findsOneWidget);
  });
}
