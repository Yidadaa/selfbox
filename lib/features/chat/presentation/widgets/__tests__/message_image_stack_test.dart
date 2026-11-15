import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';

void main() {
  for (final thumbnailState in ['valid', 'missing', 'corrupt']) {
    testWidgets(
      'image stack uses $thumbnailState thumbnail with original fallback',
      (tester) async {
        final root = createTempAppPaths().root;
        final original = File('${root.path}/image.png')
          ..writeAsBytesSync(img.encodePng(img.Image(width: 2, height: 2)));
        final thumbnail = File('${root.path}/image.thumb.png');
        if (thumbnailState == 'valid') {
          thumbnail.writeAsBytesSync(original.readAsBytesSync());
        }
        if (thumbnailState == 'corrupt') thumbnail.writeAsStringSync('invalid');
        var taps = 0;
        await tester.pumpPage(
          Center(
            child: MessageImageStack(
              paths: const ['media/image.png'],
              resolveImage: (_) => original,
              resolveThumbnail: (_) => thumbnail,
              onTap: () => taps++,
            ),
          ),
        );
        for (var frame = 0; frame < 100; frame++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
          if (tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null)) {
            break;
          }
        }
        final photo = tester.widget<Image>(find.byType(Image).last);
        final provider = photo.image as ResizeImage;
        expect(
          (provider.imageProvider as FileImage).file.path,
          thumbnailState == 'valid' ? thumbnail.path : original.path,
        );
        final decoded = tester.widget<RawImage>(find.byType(RawImage).last);
        expect(decoded.image, isNotNull);
        await tester.tap(find.byType(MessageImageStack));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
