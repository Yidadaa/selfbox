import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/data/datasources/media_store.dart';

void main() {
  group('MediaStore', () {
    late MediaStore store;
    setUp(() => store = MediaStore(createTempAppPaths()));

    test('saves bytes under media/ and returns a relative path', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final relative = (await store.saveImage(bytes, extension: '.PNG').run())
          .getOrElse((f) => fail('$f'));

      expect(relative, matches(RegExp(r'^media/[0-9a-f-]{36}\.png$')));
      final file = store.resolve(relative).toNullable();
      expect(file?.readAsBytesSync(), bytes);
    });

    test('falls back to jpg when the extension is missing', () async {
      final relative =
          (await store.saveImage(Uint8List(1), extension: '').run()).getOrElse(
            (f) => fail('$f'),
          );
      expect(p.extension(relative), '.jpg');
    });

    test('resolves to a native-separator path under the root', () {
      final file = store.resolve('media/x.jpg').toNullable();
      expect(
        file?.path,
        p.join(p.join('', file!.parent.parent.path), 'media', 'x.jpg'),
      );
    });

    test('reads back what it saved', () async {
      final relative =
          (await store
                  .saveImage(Uint8List.fromList([9]), extension: 'jpg')
                  .run())
              .getOrElse((f) => fail('$f'));
      final read = await store.read(relative).run();
      expect(read.getOrElse((f) => fail('$f')), [9]);
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

    test('delete removes the file and tolerates repeats', () async {
      final relative =
          (await store.saveImage(Uint8List(1), extension: 'jpg').run())
              .getOrElse((f) => fail('$f'));

      expect((await store.delete(relative).run()).isRight(), isTrue);
      expect(store.resolve(relative).toNullable()?.existsSync(), isFalse);
      expect((await store.delete(relative).run()).isRight(), isTrue);
    });
  });
}
