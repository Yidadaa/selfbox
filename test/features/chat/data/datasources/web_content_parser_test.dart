import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/web_content_parser.dart';

void main() {
  test('malformed optional base and icon do not discard readable metadata', () {
    final page = parseWebPage(
      '<title>Page</title><base href="http://[bad">'
          '<link rel="icon" href="http://[bad"><main>Body</main>',
      'https://example.com/path',
      'text/html',
    );
    expect(page.title, 'Page');
    expect(page.iconUrl, 'https://example.com/favicon.ico');
  });
  test('metadata prefers Open Graph and resolves relative icons', () {
    final page = parseWebPage(
      '''<title>Fallback</title>
      <meta property="og:title" content="A &amp; B">
      <meta name="description" content="Fallback summary">
      <meta property="og:description" content="Useful summary">
      <link rel="shortcut icon" href="../icon.png">
      <main>Readable body</main>''',
      'https://example.com/story/post',
      'text/html',
    );
    expect(page.title, 'A & B');
    expect(page.description, 'Useful summary');
    expect(page.iconUrl, 'https://example.com/icon.png');
  });
  test('metadata-only pages work and unsafe icons fall back to favicon', () {
    final page = parseWebPage(
      '''<title> </title>
      <meta name="twitter:title" content="Client rendered">
      <meta name="description" content="A summary">
      <link rel="icon" href="javascript:alert(1)">
      <script>render()</script>''',
      'https://example.com/app',
      'text/html',
    );
    expect(page.title, 'Client rendered');
    expect(page.description, 'A summary');
    expect(page.iconUrl, 'https://example.com/favicon.ico');
    expect(page.text, isEmpty);
  });
  test('missing metadata uses host and readable text', () {
    final page = parseWebPage(
      '<main>Hello world</main>',
      'https://example.com/page',
      'text/html',
    );
    expect(page.title, 'example.com');
    expect(page.description, 'Hello world');
    expect(page.iconUrl, 'https://example.com/favicon.ico');
  });
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
