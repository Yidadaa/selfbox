import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/platform/external_browser.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  test(
    'default adapter requests the system external application mode',
    () async {
      final previous = UrlLauncherPlatform.instance;
      final platform = _Launcher();
      UrlLauncherPlatform.instance = platform;
      addTearDown(() => UrlLauncherPlatform.instance = previous);
      expect(
        (await const ExternalBrowser().open('https://example.com').run())
            .isRight(),
        isTrue,
      );
      expect(platform.options?.mode, PreferredLaunchMode.externalApplication);
    },
  );
  test(
    'launches HTTP links and rejects unsafe schemes before platform call',
    () async {
      final opened = <Uri>[];
      final browser = ExternalBrowser(
        launch: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      expect(
        (await browser.open('https://example.com').run()).isRight(),
        isTrue,
      );
      for (final url in [
        'javascript:alert(1)',
        'file:///tmp',
        'https://user:pass@example.com',
      ]) {
        expect((await browser.open(url).run()).isLeft(), isTrue);
      }
      expect(opened, [Uri.parse('https://example.com')]);
    },
  );
  test('platform refusal and exceptions become failures', () async {
    expect(
      (await ExternalBrowser(
        launch: (_) async => false,
      ).open('https://example.com').run()).isLeft(),
      isTrue,
    );
    expect(
      (await ExternalBrowser(
        launch: (_) async => throw PlatformException(code: 'failed'),
      ).open('https://example.com').run()).isLeft(),
      isTrue,
    );
  });
}

class _Launcher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  LaunchOptions? options;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.options = options;
    return true;
  }
}
