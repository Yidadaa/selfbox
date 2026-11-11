import 'dart:async';

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
    @Default(None()) Option<AppFailure> failure,
  }) = _ComposerState;

  const ComposerState._();

  bool get canSend =>
      !sending && (text.trim().isNotEmpty || attachments.isNotEmpty);
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
  // Large photos are downscaled on pick: enough for reading on a phone and
  // for vision models, without multi-megabyte originals in every request.
  static const _maxImageSide = 2048.0;
  static const _jpegQuality = 85;

  @override
  ComposerState build() => const ComposerState();

  void setText(String text) => state = state.copyWith(text: text);

  void toggleAiMode() => state = state.copyWith(aiMode: !state.aiMode);

  void dismissFailure() => state = state.copyWith(failure: const None());

  Future<void> pickImage() async {
    final file = await ref
        .read(imagePickerProvider)
        .pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxImageSide,
          maxHeight: _maxImageSide,
          imageQuality: _jpegQuality,
        );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final saved = await ref
        .read(mediaStoreProvider)
        .saveImage(
          bytes,
          extension: p.extension(file.path.isEmpty ? file.name : file.path),
        )
        .run();
    state = saved.match(
      (failure) => state.copyWith(failure: Some(failure)),
      (path) => state.copyWith(attachments: [...state.attachments, path]),
    );
  }

  Future<void> removeAttachment(String path) async {
    state = state.copyWith(
      attachments: [...state.attachments.where((a) => a != path)],
    );
    await ref.read(mediaStoreProvider).delete(path).run();
  }

  Future<void> send() async {
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
      (_) => ComposerState(aiMode: state.aiMode),
    );
    result
        .toOption()
        .filter((message) => message.askedAi)
        .match(() {}, ref.read(onAskAiProvider));
  }
}
