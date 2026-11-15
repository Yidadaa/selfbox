import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/data/datasources/profile_entity.dart';
import 'package:selfbox/features/settings/data/repositories/local_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

import '../../../../support/temp_storage.dart';

void main() {
  test('profile persists and trims nickname', () async {
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
  });

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
  test('gallery avatar can be replaced with a preset without removing legacy user photo', () async {
    final paths = createTempAppPaths();
    final repo = LocalAccountRepository(await openTempStore(paths), paths);
    final photo =
        (await repo.importAvatar(Uint8List.fromList([1]), '.png').run())
            .getOrElse((e) => throw e);
    final legacy =
        (await repo.importAvatar(Uint8List.fromList([2]), '.png').run())
            .getOrElse((e) => throw e);
    expect(
      (await repo.save(UserProfile(avatar: legacy, agentAvatar: photo)).run())
          .isRight(),
      isTrue,
    );
    expect(
      (await repo
              .save(UserProfile(avatar: legacy, agentAvatar: 'preset:awake'))
              .run())
          .isRight(),
      isTrue,
    );
    expect(File('${paths.root.path}/$photo').existsSync(), isFalse);
    expect(File('${paths.root.path}/$legacy').existsSync(), isTrue);
  });
  test('legacy user identity stays separate from the default Agent', () async {
    final paths = createTempAppPaths();
    final store = await openTempStore(paths);
    store.box<ProfileEntity>().put(
      ProfileEntity(nickname: 'Flynn', avatar: 'media/legacy-user.jpg'),
    );
    final repo = LocalAccountRepository(store, paths);
    final old = (await repo.load().run()).getOrElse((e) => throw e);
    expect(old.nickname, 'Flynn');
    expect(old.avatar, 'media/legacy-user.jpg');
    expect(old.agentName, isEmpty);
    expect(old.agentAvatar, isNull);
    final changed = old.copyWith(
      agentName: '  Momo  ',
      agentAvatar: 'preset:reading',
    );
    expect((await repo.save(changed).run()).isRight(), isTrue);
    final loaded = (await LocalAccountRepository(
      store,
      paths,
    ).load().run()).getOrElse((e) => throw e);
    expect(loaded.agentName, 'Momo');
    expect(loaded.agentAvatar, 'preset:reading');
    expect(loaded.nickname, 'Flynn');
    expect(loaded.avatar, old.avatar);
  });

  test(
    'default identities and empty user name are valid, long names rejected',
    () async {
      final paths = createTempAppPaths();
      final repo = LocalAccountRepository(await openTempStore(paths), paths);
      expect((await repo.save(const UserProfile()).run()).isRight(), isTrue);
      for (final invalid in [
        UserProfile(agentName: 'x' * 41),
        UserProfile(nickname: 'x' * 41),
        const UserProfile(agentAvatar: 'preset:unknown'),
        const UserProfile(agentAvatar: '../outside.png'),
      ]) {
        expect((await repo.save(invalid).run()).isLeft(), isTrue);
      }
      expect(
        (await repo.load().run()).getOrElse((e) => throw e),
        const UserProfile(),
      );
    },
  );
}
