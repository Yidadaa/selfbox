import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final _first = Message(
  id: 1,
  createdAt: kTestNow,
  author: MessageAuthor.me,
  text: '周末想去湖边散步，带上相机。',
);
final _second = _first.copyWith(id: 2, text: '下午顺便去那家新开的咖啡店。');
final _reply = _first.copyWith(
  id: 3,
  text: '把这两件事安排在一起吧。',
  quotedMessageIds: [1, 2],
);
final _long = _first.copyWith(
  id: 4,
  author: MessageAuthor.ai,
  text:
      '# 轻松的周末计划\n\n先去湖边，午后再去咖啡店。\n\n'
      '${List.generate(8, (index) => '## ${index + 1}. 留一点自由时间\n\n沿着湖边慢慢走，看看树影和水面。带上相机，也别忘了享受当下。\n\n').join()}'
      '**最后：** 这次出门不用赶时间。',
);

final messageQuoteFixtures = [
  for (final brightness in Brightness.values)
    for (final mode in [
      'composer',
      'editor',
      'picker',
      'preview',
      'expanded',
      'preview_updated',
      'expanded_updated',
      'editor_updated',
      'location_updated',
    ])
      ScreenshotFixture(
        name: 'message_quotes_${mode}_${brightness.name}',
        location: mode == 'location_updated' ? '/chat/at/1' : '/chat',
        env: () => (
          paths: null,
          memory: null,
          settings: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              if (mode == 'location_updated')
                _first.copyWith(
                  text:
                      '周末想去湖边散步，带上相机。\n\n'
                      '早上沿着湖边慢慢走，拍几张喜欢的照片。走累了就找个长椅坐一会儿。\n\n'
                      '中午在附近吃点东西，下午再去那家新开的咖啡店。\n\n'
                      '不需要安排得太满，给自己留一点自由的时间。',
                )
              else
                _first,
              _second,
              _reply,
              if (mode.startsWith('preview') || mode.startsWith('expanded'))
                _long,
            ],
          ),
        ),
        setUp: (tester, container) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final composer = container.read(composerControllerProvider.notifier);
          if (mode.startsWith('preview') || mode.startsWith('expanded')) {
            composer.toggleAiMode();
          } else {
            composer
              ..quote(_first)
              ..quote(_second);
          }
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          if (mode == 'composer') {
            await tester.enterText(
              find.byType(EditableText),
              '第一行想法\n补充一点细节\n这样就很清楚了',
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 780);
          }
          if (mode.startsWith('editor')) {
            await tester.tap(find.byKey(const ValueKey('composer-quotes')));
          }
          if (mode == 'picker') {
            await tester.tap(find.text(t.chat.quotedCount(count: 2)));
          }
          if (mode.startsWith('expanded')) {
            await tester.tap(find.byKey(const ValueKey('expand-message')));
          }
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(MaterialApp));
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          await tester.runAsync(() async {
            for (final image in images) {
              await precacheImage(image.image, context);
            }
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      ),
];
