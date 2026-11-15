import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:platform_proxy/platform_proxy.dart';
import 'package:selfbox/features/chat/data/datasources/public_web_http.dart';
import 'package:selfbox/features/chat/data/repositories/bing_web_research_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final talker = Talker();
  final result = await TaskEither.tryCatch(
    () async {
      final routes = await PlatformProxy().getPlatformProxies(
        url: 'https://dart.dev/overview',
      );
      talker.info(
        'Native proxy discovery: ${routes.length} route(s), types: ${routes.map((route) => route.type).join(', ')}',
      );
      final direct = createPublicWebDio(direct: true);
      final proxy = createPublicWebDio();
      try {
        for (final entry in {'direct': direct, 'system': proxy}.entries) {
          final page = await BingWebResearchRepository(entry.value)
              .read('https://dart.dev/overview')
              .run();
          page.match(
            (failure) => talker.warning('${entry.key}: $failure'),
            (content) => talker.info(
              '${entry.key}: ${content.title}, ${content.text.length} characters',
            ),
          );
        }
        final page = await BingWebResearchRepository(
          direct,
          proxyDio: proxy,
        ).read('https://www.baidu.com').run();
        return page.match(
          (failure) {
            talker.error('Parallel read failed', failure);
            return 1;
          },
          (content) {
            talker.info(
              'Parallel read: ${content.title}, ${content.text.length} characters',
            );
            return 0;
          },
        );
      } finally {
        direct.close(force: true);
        proxy.close(force: true);
      }
    },
    (Object error, StackTrace stack) {
      talker.error('Native smoke failure', error, stack);
      return error;
    },
  ).run();
  if (arguments.isNotEmpty) {
    await File(arguments.first).writeAsString(
      talker.history.map((entry) => entry.generateTextMessage()).join('\n'),
    );
  }
  exit(result.getOrElse((_) => 1));
}
