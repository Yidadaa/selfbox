import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/pages/message_expanded_page.dart';
import 'package:selfbox/features/chat/presentation/services/message_share_renderer.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final _message = Message(
  id: 9,
  createdAt: kTestNow,
  author: MessageAuthor.ai,
  text:
      '## 给今天的你\n\n'
      '不必把每一天都过得很用力。偶尔慢一点，也是在好好生活。\n\n'
      '如果今天有些累，就先做一件小事：\n\n'
      '- 给自己倒一杯温水\n'
      '- 去窗边看看天色\n'
      '- 把脑海里的一个念头写下来\n\n'
      '> 你不用一直向前跑，我会在这里陪你。\n\n'
      '**剩下的，我们明天再慢慢来。**',
);

final messageShareFixtures = [
  for (final brightness in Brightness.values)
    ScreenshotFixture(
      name: 'message_share_${brightness.name}',
      location: '/chat/message/9',
      env: () => (
        paths: null,
        memory: null,
        settings: null,
        overrides: const [],
        messages: FakeMessageRepository(seed: [_message]),
      ),
      setUp: (tester, _) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpAndSettle();
      },
      afterOpen: (tester) async {
        expect(find.byKey(const ValueKey('share-message')), findsOneWidget);
        final context = tester.element(find.byType(MessageExpandedPage));
        final result = await tester.runAsync(
          () => renderMessageShare(context, _message).run(),
        );
        final bytes = result?.getRight().toNullable();
        expect(bytes, isNotNull, reason: '$result');
        if (bytes != null) {
          await tester.runAsync(
            () => File(
              'tool/screenshots/out/message_export_${brightness.name}.png',
            ).writeAsBytes(bytes),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    ),
];
