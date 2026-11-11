import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';

class _FakePicker extends Fake implements ImagePicker {
  _FakePicker(this.result);

  XFile? result;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => result;
}

typedef _Env = ({
  ProviderContainer container,
  FakeMessageRepository messages,
  AppPaths paths,
  List<Message> asked,
});

_Env _env({XFile? picked}) {
  final messages = FakeMessageRepository();
  final paths = createTempAppPaths();
  final asked = <Message>[];
  final container = ProviderContainer(
    overrides: [
      ...testAppOverrides(messages: messages, paths: paths),
      imagePickerProvider.overrideWithValue(_FakePicker(picked)),
      onAskAiProvider.overrideWithValue(asked.add),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, messages: messages, paths: paths, asked: asked);
}

ComposerController _ctrl(_Env env) =>
    env.container.read(composerControllerProvider.notifier);

ComposerState _state(_Env env) =>
    env.container.read(composerControllerProvider);

void main() {
  group('ComposerController', () {
    test('starts empty with AI mode off', () {
      final env = _env();
      expect(_state(env), const ComposerState());
      expect(_state(env).canSend, isFalse);
    });

    test('whitespace-only text cannot be sent', () async {
      final env = _env();
      _ctrl(env).setText('   ');
      expect(_state(env).canSend, isFalse);

      await _ctrl(env).send();
      expect(env.messages.added, isEmpty);
    });

    test('send stores a note from me and clears the draft', () async {
      final env = _env();
      _ctrl(env).setText('买牛奶');
      await _ctrl(env).send();

      expect(
        env.messages.added.single,
        const MessageDraft(author: MessageAuthor.me, text: '买牛奶'),
      );
      expect(_state(env), const ComposerState());
      expect(env.asked, isEmpty);
    });

    test('in AI mode the note is flagged, handed to the assistant, '
        'and AI mode stays on', () async {
      final env = _env();
      _ctrl(env)
        ..toggleAiMode()
        ..setText('我上周说了什么？');
      await _ctrl(env).send();

      expect(env.messages.added.single.askedAi, isTrue);
      expect(env.asked.single.text, '我上周说了什么？');
      expect(_state(env).aiMode, isTrue);
      expect(_state(env).text, isEmpty);
    });

    test('a failed send keeps the draft and exposes the failure', () async {
      final env = _env();
      env.messages.failNextAdd = const Some(
        AppFailure.database(message: 'disk full'),
      );
      _ctrl(env).setText('keep me');
      await _ctrl(env).send();

      expect(_state(env).text, 'keep me');
      expect(_state(env).sending, isFalse);
      expect(_state(env).failure.toNullable(), isA<DatabaseFailure>());

      _ctrl(env).dismissFailure();
      expect(_state(env).failure, const None());
    });

    test('picking an image saves it and adds an attachment', () async {
      final env = _env(
        picked: XFile.fromData(
          Uint8List.fromList([1, 2]),
          name: 'p.png',
          path: 'p.png',
        ),
      );
      await _ctrl(env).pickImage();

      final path = _state(env).attachments.single;
      expect(path, endsWith('.png'));
      final file = env.container.read(mediaStoreProvider).resolve(path);
      expect(file.toNullable()?.readAsBytesSync(), [1, 2]);
      expect(_state(env).canSend, isTrue);
    });

    test('cancelling the picker changes nothing', () async {
      final env = _env();
      await _ctrl(env).pickImage();
      expect(_state(env).attachments, isEmpty);
    });

    test('an image-only note can be sent', () async {
      final env = _env(
        picked: XFile.fromData(
          Uint8List.fromList([1]),
          name: 'p.jpg',
          path: 'p.jpg',
        ),
      );
      await _ctrl(env).pickImage();
      await _ctrl(env).send();

      expect(env.messages.added.single.images, hasLength(1));
      expect(_state(env).attachments, isEmpty);
    });

    test('removing an attachment deletes the stored file', () async {
      final env = _env(
        picked: XFile.fromData(
          Uint8List.fromList([1]),
          name: 'p.jpg',
          path: 'p.jpg',
        ),
      );
      await _ctrl(env).pickImage();
      final path = _state(env).attachments.single;

      await _ctrl(env).removeAttachment(path);
      expect(_state(env).attachments, isEmpty);
      final file = env.container.read(mediaStoreProvider).resolve(path);
      expect(file.toNullable()?.existsSync(), isFalse);
    });
  });
}
