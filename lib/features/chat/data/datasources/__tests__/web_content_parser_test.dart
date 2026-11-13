import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/web_content_parser.dart';

void main() {
  test('extracts plain text without scripts, styles or escaped HTML tags', () {
    final page = parseWebPage(
      '''<title>A &amp; B</title><nav>Menu</nav><main><h1>Heading</h1><p>Hello <strong>world</strong> &amp; friends.</p><p>&lt;span&gt;Escaped&lt;/span&gt;</p><style>css</style><script>steal()</script><div hidden>Hidden</div></main>''',
      'https://example.com',
      'text/html',
    );
    expect(page.title, 'A & B');
    expect(page.text, contains('Hello world & friends.'));
    expect(page.text, contains('Escaped'));
    for (final unwanted in ['<', '>', 'steal()', 'Hidden', 'css', 'Menu']) {
      expect(page.text, isNot(contains(unwanted)));
    }
    expect(page.text, contains('\n'));
  });

  test('RSS deduplicates URLs and ignores private/invalid links', () {
    final hits = parseBingResults('''<rss><channel>
      <item><title>A</title><link>https://example.com</link></item>
      <item><title>B</title><link>https://example.com</link></item>
      <item><title>Private</title><link>http://127.0.0.1</link></item>
      <item><title>Invalid</title><link>javascript:alert(1)</link></item>
    </channel></rss>''', 10);
    expect(hits, hasLength(1));
    expect(parseBingResults('<rss><channel/></rss>', 5), isEmpty);
  });
}
