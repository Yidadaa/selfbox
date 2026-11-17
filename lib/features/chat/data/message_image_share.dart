import 'dart:typed_data';
import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/app_failure.dart';

part '../../../gen/features/chat/data/message_image_share.g.dart';

typedef ShareMessageImage = TaskEither<AppFailure, Unit> Function(
  Uint8List bytes,
  Rect origin,
);

@riverpod
ShareMessageImage shareMessageImage(Ref ref) =>
    (bytes, origin) => sharePng(SharePlus.instance, bytes, origin);

TaskEither<AppFailure, Unit> sharePng(
  SharePlus share,
  Uint8List bytes,
  Rect origin,
) => TaskEither.tryCatch(() async {
  await share.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png')],
      fileNameOverrides: const ['xiaolan-message.png'],
      sharePositionOrigin: origin,
    ),
  );
  return unit;
}, AppFailure.fromError);
