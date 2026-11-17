import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:selfbox/features/chat/data/message_image_share.dart';
import 'package:share_plus/share_plus.dart';

class _Share extends Mock implements SharePlus {}

void main() {
  setUpAll(() => registerFallbackValue(ShareParams(text: 'fallback')));
  for (final status in [
    ShareResultStatus.success,
    ShareResultStatus.dismissed,
  ]) {
    test(
      'shares PNG bytes with filename and iPad anchor; $status is not an error',
      () async {
        final share = _Share();
        when(() => share.share(any()))
            .thenAnswer((_) async => ShareResult('', status));
        final bytes = Uint8List.fromList([137, 80, 78, 71]);
        const origin = Rect.fromLTWH(300, 40, 48, 48);
        final result = await sharePng(share, bytes, origin).run();
        expect(result.isRight(), true);
        final params =
            verify(() => share.share(captureAny())).captured.single
                as ShareParams;
        expect(params.sharePositionOrigin, origin);
        expect(params.fileNameOverrides, ['xiaolan-message.png']);
        final file = params.files?.single;
        expect(file?.mimeType, 'image/png');
        expect(await file?.readAsBytes(), bytes);
      },
    );
  }
  test('platform error is converted to a failure', () async {
    final share = _Share();
    when(() => share.share(any())).thenThrow(StateError('platform failed'));
    expect(
      (await sharePng(
        share,
        Uint8List(4),
        const Rect.fromLTWH(0, 0, 48, 48),
      ).run()).isLeft(),
      true,
    );
  });
}
