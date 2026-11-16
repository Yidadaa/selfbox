import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

Future<void> prepareLongChat(ProviderContainer container) async {
  final repository = container.read(messageRepositoryProvider);
  final existing = await repository.latest(10000).run();
  if (existing.isLeft() ||
      existing
          .getOrElse((_) => [])
          .any((message) => !message.text.contains('Profile fixture '))) {
    throw StateError('Only replace the dedicated profile fixture store');
  }
  final cleared = await repository.clearAll().run();
  if (cleared.isLeft()) throw StateError('Cannot replace fixtures');
  for (var index = 0; index < 100; index++) {
    final text = index.isEven
        ? 'Profile fixture $index：请整理这份长篇计划，保留细节、清单和代码示例。'
        : '# Profile fixture $index · 长篇计划\n\n${List.generate(16, (section) => '## ${section + 1}. 计划与执行\n\n'
              '这一部分记录项目的背景、目标与具体安排。先整理需求，再核对边界，'
              '让每一步都有明确的输入和可以验证的结果。中文与 English 混排用于检查真实文字布局。\n\n'
              '- **检查重点**：保持原有玻璃效果和动效。\n'
              '- 长列表滚动时逐条加载，返回新消息后再次检查。\n\n'
              '> 记录实际观测，不用理论帧率替代测量。\n\n'
              '行内代码 `final section = $section;` 和普通正文共同展示。\n\n').join()}';
    final result = await repository
        .add(
          MessageDraft(
            author: index.isEven ? MessageAuthor.me : MessageAuthor.ai,
            text: text,
            askedAi: index.isEven,
          ),
        )
        .run();
    if (result.isLeft()) throw StateError('Fixture insertion failed');
  }
}
