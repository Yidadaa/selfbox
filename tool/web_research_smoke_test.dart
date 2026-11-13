import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';

void main() {
  test('live Bing RSS and HTTP page reading', () async {
    final dio = createPublicWebDio();
    addTearDown(() => dio.close(force: true));
    final repository = BingWebResearchRepository(dio);
    final search = await repository.search('flutter.dev', limit: 3).run();
    expect(
      search.isRight(),
      isTrue,
      reason: '${search.getLeft().toNullable()}',
    );
    final hits = search.toNullable() ?? const [];
    expect(hits, isNotEmpty);
    final page = await repository.read('https://dart.dev/overview').run();
    expect(page.isRight(), isTrue, reason: '${page.getLeft().toNullable()}');
    final text = page.toNullable()?.text ?? '';
    expect(text, isNotEmpty);
    expect(text, isNot(contains('<html')));
  });
}
