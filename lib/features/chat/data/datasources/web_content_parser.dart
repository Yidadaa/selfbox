import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/web_research_repository.dart';
import 'public_web_http.dart';

List<WebSearchHit> parseBingResults(String source, int limit) {
  final document = XmlDocument.parse(source);
  if (document.rootElement.name.local != 'rss') {
    throw const AppFailure.network(
      message: 'Bing returned an unsupported response',
    );
  }
  final seen = <String>{};
  final hits = <WebSearchHit>[];
  for (final item in document.findAllElements('item')) {
    final url = item.getElement('link')?.innerText.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || !isPublicWebUri(uri) || !seen.add(url)) continue;
    final title = plainText(item.getElement('title')?.innerText ?? '');
    if (title.isEmpty) continue;
    hits.add(
      WebSearchHit(
        title: clipWebText(title, 300),
        url: url,
        snippet: clipWebText(
          plainText(item.getElement('description')?.innerText ?? ''),
          1000,
        ),
      ),
    );
    if (hits.length >= limit) break;
  }
  return hits;
}

WebPageContent parseWebPage(String source, String url, String contentType) {
  if (contentType == 'text/plain') {
    final text = plainText(source);
    return WebPageContent(
      title: Uri.parse(url).host,
      url: url,
      text: clipWebText(text, maxWebText),
      description: clipWebText(text, 300),
      truncated: text.length > maxWebText,
    );
  }
  final document = html.parse(source);
  final title = clipWebText(
    _firstNonEmpty([
      _meta(document, 'og:title'),
      _meta(document, 'twitter:title'),
      document.querySelector('title')?.text ?? '',
      Uri.parse(url).host,
    ]),
    300,
  );
  final description = _firstNonEmpty([
    _meta(document, 'og:description'),
    _meta(document, 'description'),
    _meta(document, 'twitter:description'),
  ]);
  final iconUrl = _iconUrl(document, Uri.parse(url));
  for (final node in document.querySelectorAll(
    'script,style,noscript,nav,footer,header,aside,form,svg,canvas,iframe,[hidden],[aria-hidden="true"]',
  )) {
    node.remove();
  }
  final body =
      document.querySelector('article') ??
      document.querySelector('main') ??
      document.body;
  if (body == null) {
    throw const AppFailure.network(message: 'No readable page content');
  }
  final buffer = StringBuffer();
  _writeText(body, buffer);
  final text = buffer
      .toString()
      .replaceAll(RegExp(r'</?[A-Za-z][^>]*>'), '')
      .replaceAll(RegExp(r'[<>]'), '')
      .replaceAll(RegExp(r'[ \t\r]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return WebPageContent(
    title: title,
    url: url,
    text: clipWebText(text, maxWebText),
    description: clipWebText(
      description.isEmpty ? plainText(text) : description,
      300,
    ),
    iconUrl: iconUrl,
    truncated: text.length > maxWebText,
  );
}

String _meta(Document document, String name) =>
    document
        .querySelector('meta[property="$name"],meta[name="$name"]')
        ?.attributes['content'] ??
    '';

String _firstNonEmpty(List<String> values) =>
    values.map(plainText).where((value) => value.isNotEmpty).firstOrNull ?? '';

String _iconUrl(Document document, Uri page) {
  final baseReference = Uri.tryParse(
    document.querySelector('base[href]')?.attributes['href'] ?? '',
  );
  final baseCandidate = baseReference == null
      ? page
      : page.resolveUri(baseReference);
  final base = isPublicWebUri(baseCandidate) ? baseCandidate : page;
  for (final link in document.querySelectorAll('link[rel][href]')) {
    final rel = (link.attributes['rel'] ?? '').toLowerCase().split(
      RegExp(r'\s+'),
    );
    if (!rel.contains('icon') && !rel.contains('apple-touch-icon')) continue;
    final reference = Uri.tryParse(link.attributes['href'] ?? '');
    if (reference == null) continue;
    final icon = base.resolveUri(reference);
    if (isPublicWebUri(icon)) return icon.toString();
  }
  return page.resolve('/favicon.ico').toString();
}

const maxWebText = 80000;

String plainText(String source) => (html.parseFragment(source).text ?? '')
    .replaceAll(RegExp(r'</?[A-Za-z][^>]*>'), '')
    .replaceAll(RegExp(r'[<>]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String clipWebText(String text, int length) {
  if (text.length <= length) return text;
  final last = text.codeUnitAt(length - 1);
  return text.substring(
    0,
    last >= 0xd800 && last <= 0xdbff ? length - 1 : length,
  );
}

void _writeText(Node node, StringBuffer buffer) {
  if (buffer.length > maxWebText) return;
  if (node is Text) {
    buffer.write(node.data);
    return;
  }
  final block =
      node is Element &&
      const {
        'p',
        'div',
        'section',
        'article',
        'main',
        'h1',
        'h2',
        'h3',
        'h4',
        'li',
        'tr',
        'br',
        'pre',
        'blockquote',
      }.contains(node.localName);
  if (block) {
    buffer.writeln();
  }
  for (final child in node.nodes) {
    _writeText(child, buffer);
  }
  if (block) {
    buffer.writeln();
  }
}
