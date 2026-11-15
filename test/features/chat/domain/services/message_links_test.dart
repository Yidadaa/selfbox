import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/services/message_links.dart';

void main() {
  test('extracts multiple links without swallowing Chinese punctuation', () {
    const text = '看 https://example.com/a?q=1&b=2，和 www.dart.dev。';
    final links = extractMessageLinks(text);
    expect(links.map((link) => link.url), [
      'https://example.com/a?q=1&b=2',
      'https://www.dart.dev',
    ]);
    expect(links.map((link) => text.substring(link.start, link.end)), [
      'https://example.com/a?q=1&b=2',
      'www.dart.dev',
    ]);
    expect(singleMessageLink(text), isNull);
  });
  test('keeps balanced URL parentheses and trims surrounding punctuation', () {
    expect(
      extractMessageLinks('(https://example.com/a_(b)).').single.url,
      'https://example.com/a_(b)',
    );
    expect(
      singleMessageLink(' \nhttps://example.com/a?x=1#part\t'),
      'https://example.com/a?x=1#part',
    );
    expect(singleMessageLink('www.example.com'), 'https://www.example.com');
    expect(singleMessageLink('https://example.com.'), isNull);
  });
  test('rejects empty, malformed, credentials and executable schemes', () {
    for (final text in [
      '',
      'hello',
      'https://',
      'javascript:alert(1)',
      'file:///tmp/file',
      'https://user:secret@example.com',
      'https://example.com https://dart.dev',
    ]) {
      expect(singleMessageLink(text), isNull, reason: text);
    }
    expect(extractMessageLinks('javascript:https://example.com'), isEmpty);
  });
}
