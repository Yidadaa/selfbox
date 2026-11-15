import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../error/app_failure.dart';

part '../../gen/core/platform/external_browser.g.dart';

@riverpod
ExternalBrowser externalBrowser(Ref ref) => const ExternalBrowser();

class ExternalBrowser {
  const ExternalBrowser({this.launch = _launch});
  final Future<bool> Function(Uri) launch;

  TaskEither<AppFailure, Unit> open(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        value.contains(RegExp(r'\s'))) {
      return TaskEither.left(
        const AppFailure.validation(message: 'Invalid web link'),
      );
    }
    return TaskEither.tryCatch(() => launch(uri), AppFailure.fromError).flatMap(
      (opened) => opened
          ? TaskEither.right(unit)
          : TaskEither.left(
              const AppFailure.validation(message: 'Unable to open browser'),
            ),
    );
  }
}

Future<bool> _launch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
