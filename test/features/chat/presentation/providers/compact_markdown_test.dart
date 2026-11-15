import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/presentation/providers/compact_markdown.dart';

void main() {
  test('compact classification preserves inline and bounded block layouts', () {
    final cache = CompactMarkdownCache();
    for (final text in [
      'Hello',
      '**Hi**',
      '`code`',
      '[link](https://example.com)',
      '# Heading',
    ]) {
      expect(cache.isCompact(text), isTrue, reason: text);
    }
    for (final text in [
      '- list',
      '> quote',
      '```dart\nfinal value = 1;\n```',
      r'$$ x^2 $$',
      '![image](https://example.com/a.png)',
    ]) {
      expect(cache.isCompact(text), isFalse, reason: text);
    }
  });

  test('classification cache reuses parses and evicts the oldest entry', () {
    var parses = 0;
    final cache = CompactMarkdownCache(
      parse: (text) {
        parses++;
        return MarkdownParser().parse(text);
      },
    );
    cache.isCompact('first');
    cache.isCompact('first');
    expect(parses, 1);
    for (var index = 0; index < CompactMarkdownCache.capacity; index++) {
      cache.isCompact('message $index');
    }
    final before = parses;
    cache.isCompact('first');
    expect(parses, before + 1);
    cache.isCompact('message ${CompactMarkdownCache.capacity - 1}');
    expect(parses, before + 1);
  });
}
