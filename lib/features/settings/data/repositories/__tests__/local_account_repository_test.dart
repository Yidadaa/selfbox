import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/settings/data/repositories/local_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

void main() {
  test(
    'profile persists, trims nickname and rejects empty/long names',
    () async {
      final paths = createTempAppPaths();
      final store = await openTempStore(paths);
      final repo = LocalAccountRepository(store, paths);
      expect(
        (await repo.load().run()).getOrElse((e) => throw e),
        const UserProfile(),
      );
      expect(
        (await repo.save(const UserProfile(nickname: '  Flynn  ')).run())
            .isRight(),
        true,
      );
      expect(
        (await LocalAccountRepository(
          store,
          paths,
        ).load().run()).getOrElse((e) => throw e).nickname,
        'Flynn',
      );
      for (final name in ['', '   ', 'a' * 41]) {
        expect(
          (await repo.save(UserProfile(nickname: name)).run()).isLeft(),
          true,
        );
      }
    },
  );

  test(
    'avatar, usage and idempotent cleanup preserve the open database',
    () async {
      final paths = createTempAppPaths();
      final store = await openTempStore(paths);
      final repo = LocalAccountRepository(store, paths);
      final avatar =
          (await repo.importAvatar(Uint8List.fromList([1, 2, 3]), 'png').run())
              .getOrElse((e) => throw e);
      await repo.save(UserProfile(nickname: 'Flynn', avatar: avatar)).run();
      final usage = (await repo.usage().run()).getOrElse((e) => throw e);
      expect(usage.mediaBytes, 3);
      expect(usage.databaseBytes, greaterThan(0));
      expect((await repo.clear().run()).isRight(), true);
      expect((await repo.clear().run()).isRight(), true);
      expect(await paths.media.exists(), false);
      expect(await Directory(paths.database.path).exists(), true);
      expect(
        (await repo.load().run()).getOrElse((e) => throw e),
        const UserProfile(),
      );
      expect(
        (await repo.save(const UserProfile(nickname: 'Again')).run()).isRight(),
        true,
      );
    },
  );
}
