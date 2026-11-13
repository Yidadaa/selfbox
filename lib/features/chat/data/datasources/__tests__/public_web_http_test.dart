import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';

void main() {
  test('only public HTTP destinations are accepted', () {
    for (final url in [
      'https://example.com/news',
      'http://www.bing.com/search',
    ]) {
      expect(isPublicWebUri(Uri.parse(url)), isTrue, reason: url);
    }
    for (final url in [
      'file:///etc/passwd',
      'http://localhost/',
      'http://127.0.0.1/',
      'http://192.168.1.2/',
      'http://10.1.2.3/',
      'http://169.254.169.254/',
      'http://example.local/',
      'https://user:pass@example.com/',
      'https://example.com:8080/',
      'https://example.invalid/',
    ]) {
      expect(isPublicWebUri(Uri.parse(url)), isFalse, reason: url);
    }
    expect(isPublicWebAddress(InternetAddress('8.8.8.8')), isTrue);
    expect(isPublicWebAddress(InternetAddress('::1')), isFalse);
    expect(isPublicWebAddress(InternetAddress('fc00::1')), isFalse);
  });
}
