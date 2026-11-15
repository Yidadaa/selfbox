import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/link_preview_entity.dart';

void main() {
  test('maps persisted metadata without retaining scraped page text', () {
    final row = LinkPreviewEntity(
      sourceUrl: 'https://example.com',
      url: 'https://example.com/final',
      title: 'Title',
      description: 'Summary',
      iconUrl: 'https://example.com/icon.png',
    );
    final page = row.toDomain();
    expect(page.title, 'Title');
    expect(page.description, 'Summary');
    expect(page.iconUrl, row.iconUrl);
    expect(page.url, row.url);
    expect(page.text, isEmpty);
    expect(page.copyWith(), page);
  });
}
