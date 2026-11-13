import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/settings/data/datasources/profile_entity.dart';
import 'package:selfbox/features/settings/data/repositories/local_account_repository.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

void main() {
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
