import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/data/message_image_share.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/services/message_share_renderer.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import 'chat_page_test_support.dart';

void main() {
  testWidgets(
    'AI detail shares its message, disables pending action and retries',
    (tester) async {
      final message = testMessage(
        4,
        'the complete reply',
        author: MessageAuthor.ai,
      );
      var capture = Completer<Either<AppFailure, Uint8List>>();
      var shares = 0;
      final container = await tester.pumpApp(
        messages: FakeMessageRepository(seed: [message]),
        overrides: [
          messageShareRendererProvider.overrideWithValue((context, captured) {
            expect(captured, message);
            return TaskEither(() => capture.future);
          }),
          shareMessageImageProvider.overrideWithValue((bytes, origin) {
            expect(bytes, [1, 2, 3]);
            expect(origin.width, greaterThanOrEqualTo(48));
            expect(origin.left, greaterThan(kPhoneViewport.width / 2));
            shares++;
            return TaskEither.right(unit);
          }),
        ],
      );
      container.read(appRouterProvider).go('/chat/message/4');
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('share-message'));
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<GlassIconButton>(button).onPressed, isNull);
      capture.complete(
        const Left(AppFailure.validation(message: 'capture failed')),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.chat.shareFailed), findsOneWidget);
      expect(shares, 0);
      capture = Completer<Either<AppFailure, Uint8List>>();
      await tester.tap(button);
      capture.complete(Right(Uint8List.fromList([1, 2, 3])));
      await tester.pumpAndSettle();
      expect(shares, 1);
      expect(
        container.read(appRouterProvider).state.matchedLocation,
        '/chat/message/4',
      );
      container.read(appRouterProvider).go('/chat/message/999');
      await tester.pumpAndSettle();
      expect(button, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
