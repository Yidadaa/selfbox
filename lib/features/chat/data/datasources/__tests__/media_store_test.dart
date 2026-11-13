import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/datasources/media_store.dart';

Uint8List _jpeg({int width = 640, int height = 480}) =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: width, height: height)));

void main() {
  group('MediaStore', () {
    late MediaStore store;
    setUp(() => store = MediaStore(createTempAppPaths()));

    test('normalizes stored photos to bounded JPEG files', () async {
      final relative =
          (await store.saveImage(_jpeg(width: 3600, height: 1800)).run())
              .getOrElse((failure) => fail('$failure'));

      expect(relative, matches(RegExp(r'^media/[0-9a-f-]{36}\.jpg$')));
      final stored = (await store.read(relative).run()).getOrElse(
        (failure) => fail('$failure'),
      );
      final decoded = img.decodeImage(stored);
      expect(decoded, isNotNull);
      expect(decoded!.width, 2048);
      expect(decoded.height, 1024);
    });

    test('creates a small JPEG thumbnail beside its full-size image', () async {
      final relative = (await store.saveImage(_jpeg()).run()).getOrElse(
        (failure) => fail('$failure'),
      );
      final thumbnail = store.thumbnail(relative).toNullable();
      expect(thumbnail, isNotNull);
      expect(thumbnail!.existsSync(), isTrue);

      final decoded = img.decodeImage(thumbnail.readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, 320);
      expect(decoded.height, 240);
    });

    test('rejects corrupt image bytes without creating files', () async {
      final result = await store.saveImage(Uint8List.fromList([1, 2, 3])).run();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('thumbnail path rejects media paths outside its root', () {
      expect(store.thumbnail('../private.jpg'), isA<None>());
    });

    test('resolves to a native-separator path under the root', () {
      final file = store.resolve('media/x.jpg').toNullable();
      expect(
        file?.path,
        p.join(p.join('', file!.parent.parent.path), 'media', 'x.jpg'),
      );
    });

    test('reads back the optimized image', () async {
      final relative = (await store.saveImage(_jpeg()).run()).getOrElse(
        (failure) => fail('$failure'),
      );
      final read = await store.read(relative).run();
      expect(
        img.decodeImage(read.getOrElse((failure) => fail('$failure'))),
        isNotNull,
      );
    });

    for (final hostile in [
      '../secret.db',
      'media/../../etc/passwd',
      '/etc/passwd',
      r'C:\Windows\win.ini',
      'memory/user/profile.md',
      'media',
    ]) {
      test('refuses to resolve "$hostile"', () {
        expect(store.resolve(hostile), isA<None>());
      });
    }

    test('reading a missing file is a database failure', () async {
      final result = await store.read('media/missing.jpg').run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('reading an escaping path is a validation failure', () async {
      final result = await store.read('../x').run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('delete removes both files and tolerates repeats', () async {
      final relative = (await store.saveImage(_jpeg()).run()).getOrElse(
        (failure) => fail('$failure'),
      );
      final original = store.resolve(relative).toNullable()!;
      final thumbnail = store.thumbnail(relative).toNullable()!;

      expect((await store.delete(relative).run()).isRight(), isTrue);
      expect(original.existsSync(), isFalse);
      expect(thumbnail.existsSync(), isFalse);
      expect((await store.delete(relative).run()).isRight(), isTrue);
    });
  });
}
