import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/presentation/pages/message_search_page.dart';
import 'package:selfbox/features/settings/presentation/pages/me_page.dart';
import 'package:selfbox/features/settings/presentation/pages/profile_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  testWidgets('header opens settings, profile, and message search', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    tester.view.physicalSize = const Size(320 * 3, 844 * 3);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<GlassAppBar>(find.byType(GlassAppBar)).toolbarHeight,
      AppSizes.chatHeaderHeight,
    );
    expect(
      tester
          .widgetList<GlassIconButton>(find.byType(GlassIconButton))
          .every((button) => button.quality == GlassQuality.standard),
      isTrue,
    );
    expect(
      tester
          .widget<GlassContainer>(
            find.byKey(const ValueKey('chat-header-profile-surface')),
          )
          .quality,
      GlassQuality.standard,
    );
    final avatar = tester.getRect(
      find.byKey(const ValueKey('chat-header-avatar')),
    );
    final name = tester.getRect(
      find.byKey(const ValueKey('chat-header-profile-surface')),
    );
    expect(avatar.width, greaterThan(44));
    expect(avatar.center.dx, closeTo(name.center.dx, 0.01));
    expect(name.top, lessThan(avatar.bottom));
    expect(name.center.dy, greaterThan(avatar.center.dy));
    expect(
      tester.widget<Text>(find.text(t.me.agentDefaultName)).style?.fontSize,
      lessThan(18),
    );
    final profileStack = tester.widget<Stack>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('chat-header-avatar')),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(
      (profileStack.children.last as Positioned).child.key,
      const ValueKey('chat-header-avatar'),
    );

    await tester.tap(find.bySemanticsLabel(t.chat.openSettings));
    await tester.pumpAndSettle();
    expect(find.byType(MePage), findsOneWidget);
    container.read(appRouterProvider).go('/chat');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat-header-profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    container.read(appRouterProvider).go('/chat');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.chat.searchMessages));
    await tester.pumpAndSettle();
    expect(find.byType(MessageSearchPage), findsOneWidget);
  });
}
