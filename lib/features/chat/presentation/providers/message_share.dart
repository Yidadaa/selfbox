import 'dart:typed_data';
import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/message_image_share.dart';

part '../../../../gen/features/chat/presentation/providers/message_share.g.dart';

@riverpod
class MessageShare extends _$MessageShare {
  @override
  FutureOr<void> build(int id) {}

  Future<Either<AppFailure, Unit>> share({
    required TaskEither<AppFailure, Uint8List> image,
    required Rect origin,
  }) async {
    if (state.isLoading) return const Right(unit);
    state = const AsyncLoading();
    final send = ref.read(shareMessageImageProvider);
    final result = await image.flatMap((bytes) => send(bytes, origin)).run();
    if (ref.mounted) state = const AsyncData(null);
    return result;
  }
}
