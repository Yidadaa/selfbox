typedef MessageLink = ({int start, int end, String url});

final _linkPattern = RegExp(
  r'''(?:https?://|www\.)[^\s<>"'，。！？；：、（）【】「」『』]+''',
  caseSensitive: false,
);

List<MessageLink> extractMessageLinks(String text) => [
  for (final match in _linkPattern.allMatches(text))
    if (_startsLink(text, match.start)) ..._parseMatch(text, match),
];

String? singleMessageLink(String text) {
  final trimmed = text.trim();
  final links = extractMessageLinks(trimmed);
  if (links.length != 1) return null;
  final link = links.single;
  return link.start == 0 && link.end == trimmed.length ? link.url : null;
}

Uri? browserUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !const ['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      value.contains(RegExp(r'\s')) ||
      value.length > 4096) {
    return null;
  }
  return uri;
}

bool _startsLink(String text, int start) =>
    start == 0 || !RegExp(r'[A-Za-z0-9_@:/]').hasMatch(text[start - 1]);

Iterable<MessageLink> _parseMatch(String text, RegExpMatch match) sync* {
  var candidate = text.substring(match.start, match.end);
  while (candidate.isNotEmpty) {
    final last = candidate[candidate.length - 1];
    final opener = switch (last) {
      ')' => '(',
      ']' => '[',
      '}' => '{',
      _ => null,
    };
    final unbalanced =
        opener != null &&
        last.allMatches(candidate).length > opener.allMatches(candidate).length;
    if (!'.,!?;:'.contains(last) && !unbalanced) break;
    candidate = candidate.substring(0, candidate.length - 1);
  }
  final url = candidate.toLowerCase().startsWith('www.')
      ? 'https://$candidate'
      : candidate;
  if (browserUri(url) != null) {
    yield (start: match.start, end: match.start + candidate.length, url: url);
  }
}
