import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import 'assistant_controller.dart';

part '../../../../gen/features/chat/presentation/providers/composer_controller.freezed.dart';
part '../../../../gen/features/chat/presentation/providers/composer_controller.g.dart';

@freezed
abstract class ComposerState with _$ComposerState {
  const factory ComposerState({
    @Default('') String text,

    /// Already-saved media paths waiting to be sent.
    @Default(<String>[]) List<String> attachments,

    /// When on, a sent note is also a question to the assistant.
    @Default(false) bool aiMode,
    @Default(false) bool sending,
    @Default(false) bool picking,
    int? lastSentMessageId,
    @Default(None()) Option<AppFailure> failure,
  }) = _ComposerState;

  const ComposerState._();

  bool get canSend =>
      !sending &&
      !picking &&
      (text.trim().isNotEmpty || attachments.isNotEmpty);
}

@Riverpod(keepAlive: true)
ImagePicker imagePicker(Ref ref) => ImagePicker();

/// Called with every note sent in AI mode; tests override it to observe
/// hand-offs without running the agent.
@Riverpod(keepAlive: true)
void Function(Message) onAskAi(Ref ref) =>
    (question) =>
        unawaited(ref.read(assistantControllerProvider.notifier).ask(question));

@Riverpod(keepAlive: true)
class ComposerController extends _$ComposerController {
  Future<void>? _pending;
  // Large photos are downscaled on pick: enough for reading on a phone and
  // for vision models, without multi-megabyte originals in every request.
  static const _maxImageSide = 2048.0;
  static const _jpegQuality = 85;

  @override
  ComposerState build() => const ComposerState();

  void setText(String text) => state = state.copyWith(text: text);

  void toggleAiMode() => state = state.copyWith(aiMode: !state.aiMode);

  void dismissFailure() => state = state.copyWith(failure: const None());

  Future<void> pickImage() {
    if (state.picking || state.sending) return Future.value();
    return _pending = _pickImages();
  }

  Future<void> _pickImages() async {
    state = state.copyWith(picking: true, failure: const None());
    final picked = await TaskEither.tryCatch(
      () => ref
          .read(imagePickerProvider)
          .pickMultiImage(
            maxWidth: _maxImageSide,
            maxHeight: _maxImageSide,
            imageQuality: _jpegQuality,
          ),
      _pickFailure,
    ).run();
    for (final file in picked.getOrElse((_) => [])) {
      final saved = await TaskEither.tryCatch(file.readAsBytes, _pickFailure)
          .flatMap(
            (bytes) => ref
                .read(mediaStoreProvider)
                .saveImage(
                  bytes,
                  extension: p.extension(
                    file.path.isEmpty ? file.name : file.path,
                  ),
                ),
          )
          .run();
      state = saved.match(
        (failure) => state.copyWith(failure: Some(failure)),
        (path) => state.copyWith(attachments: [...state.attachments, path]),
      );
    }
    state = state.copyWith(
      picking: false,
      failure: picked.fold(Some.new, (_) => state.failure),
    );
  }

  static AppFailure _pickFailure(Object error, StackTrace _) => switch (error) {
    PlatformException(code: 'photo_access_denied') =>
      const AppFailure.permissionDenied(permission: 'photos'),
    _ => AppFailure.unexpected(error: error),
  };

  Future<void> finishPending() async => _pending;

  void resetDraft() => state = const ComposerState();

  Future<void> removeAttachment(String path) async {
    state = state.copyWith(
      attachments: [...state.attachments.where((a) => a != path)],
    );
    await ref.read(mediaStoreProvider).delete(path).run();
  }

  Future<void> send() {
    if (!state.canSend) return Future.value();
    return _pending = _send();
  }

  Future<void> _send() async {
    if (!state.canSend) return;
    final draft = MessageDraft(
      author: MessageAuthor.me,
      text: state.text,
      images: state.attachments,
      askedAi: state.aiMode,
    );
    state = state.copyWith(sending: true, failure: const None());
    final result = await ref.read(messageRepositoryProvider).add(draft).run();
    state = result.match(
      (failure) => state.copyWith(sending: false, failure: Some(failure)),
      (message) =>
          ComposerState(aiMode: state.aiMode, lastSentMessageId: message.id),
    );
    result
        .toOption()
        .filter((message) => message.askedAi)
        .match(() {}, ref.read(onAskAiProvider));
  }
}
