import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/chat/data/message_image_share.dart';
import 'package:selfbox/features/chat/presentation/providers/message_share.dart';

void main() {
  test('sharing serializes captures and retries after failure', () async {
    var shares = 0;
    final container = ProviderContainer(
      overrides: [
        shareMessageImageProvider.overrideWithValue((bytes, origin) {
          shares++;
          expect(bytes, [1, 2, 3]);
          expect(origin, const Rect.fromLTWH(10, 10, 48, 48));
          return TaskEither.right(unit);
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(messageShareProvider(7), (_, _) {});
    addTearDown(subscription.close);
    final action = container.read(messageShareProvider(7).notifier);
    final pending = Completer<Either<AppFailure, Uint8List>>();
    const origin = Rect.fromLTWH(10, 10, 48, 48);
    final first = action.share(
      image: TaskEither(() => pending.future),
      origin: origin,
    );
    expect(container.read(messageShareProvider(7)).isLoading, true);
    await action.share(image: TaskEither.right(Uint8List(0)), origin: origin);
    expect(shares, 0);
    pending.complete(
      const Left(AppFailure.validation(message: 'capture failed')),
    );
    expect((await first).isLeft(), true);
    expect(container.read(messageShareProvider(7)).isLoading, false);
    expect(
      (await action.share(
        image: TaskEither.right(Uint8List.fromList([1, 2, 3])),
        origin: origin,
      )).isRight(),
      true,
    );
    expect(shares, 1);
  });
}
