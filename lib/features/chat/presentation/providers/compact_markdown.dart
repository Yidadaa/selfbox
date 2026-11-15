import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../../gen/features/chat/presentation/providers/compact_markdown.g.dart';

@riverpod
CompactMarkdownCache compactMarkdownCache(Ref ref) => CompactMarkdownCache();

class CompactMarkdownCache {
  CompactMarkdownCache({List<MarkdownNode> Function(String)? parse})
    : _parse = parse ?? MarkdownParser().parse;

  static const capacity = 100;
  final List<MarkdownNode> Function(String) _parse;
  final _entries = <String, bool>{};

  bool isCompact(String text) {
    final cached = _entries.remove(text);
    if (cached != null) {
      _entries[text] = cached;
      return cached;
    }
    final compact = _parse(text).every(_intrinsicText);
    if (_entries.length == capacity) _entries.remove(_entries.keys.first);
    _entries[text] = compact;
    return compact;
  }
}

bool _intrinsicText(MarkdownNode node) => switch (node) {
  TextNode() || InlineCodeNode() || HardBreakNode() => true,
  ParagraphNode(:final children) ||
  BoldNode(:final children) ||
  ItalicNode(:final children) ||
  StrikethroughNode(:final children) ||
  LinkNode(:final children) => children.every(_intrinsicText),
  HeaderNode(:final children) =>
    children == null || children.every(_intrinsicText),
  _ => false,
};
