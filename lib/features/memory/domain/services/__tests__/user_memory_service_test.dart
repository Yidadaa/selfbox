import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/features/memory/domain/services/user_memory_service.dart';

void main() {
  test('creates the starter user.md only once', () async {
    final memory = FakeMemoryRepository();
    final service = UserMemoryService(memory);
    expect((await service.ensure('').run()).isRight(), isTrue);
    expect(memory.contentOf('user.md'), '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n');
    expect((await service.ensure('').run()).isRight(), isTrue);
    expect((await memory.list().run()).toNullable(), hasLength(1));
  });

  test(
    'name changes update the hint and keep additional personal notes',
    () async {
      final memory = FakeMemoryRepository(
        seed: {'user.md': '用户尚未设置名字，可以引导用户点击头像设置名字和头像。\n喜欢散步。\n'},
      );
      expect(
        (await UserMemoryService(memory).ensure('Flynn').run()).isRight(),
        isTrue,
      );
      expect(memory.contentOf('user.md'), '用户已经设置了名字，请优先用用户的名字称呼他。\n喜欢散步。\n');
    },
  );

  test('a fully edited user.md is left untouched', () async {
    final memory = FakeMemoryRepository(seed: {'user.md': '我的私人记忆\n'});
    await UserMemoryService(memory).ensure('Flynn').run();
    expect(memory.contentOf('user.md'), '我的私人记忆\n');
  });
}
