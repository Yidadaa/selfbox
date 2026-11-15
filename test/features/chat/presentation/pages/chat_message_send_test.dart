import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:selfbox/features/chat/presentation/pages/chat_page.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_feed.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_image_stack.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';
import 'package:selfbox/features/chat/presentation/widgets/welcome_timeline.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_message_repository.dart';
import 'chat_page_test_support.dart';

class _SingleImagePicker extends Fake implements ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [
    XFile.fromData(
      Uint8List.fromList(img.encodeJpg(img.Image(width: 16, height: 16))),
      name: 'photo.png',
      path: 'photo.png',
    ),
  ];
}

void main() {
  testWidgets('only a newly sent bubble enters from the composer', (
    tester,
  ) async {
    final messages = FakeMessageRepository(seed: [testMessage(1, 'older')]);
    await tester.pumpApp(messages: messages);
    expect(find.byType(OutgoingMessageEntrance), findsNothing);

    await tester.enterText(composerField(), 'new note');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pump();
    await tester.pump();

    final incoming = find.ancestor(
      of: find.text('new note'),
      matching: find.byType(OutgoingMessageEntrance),
    );
    expect(incoming, findsOneWidget);
    expect(
      tester
          .widget<SizeTransition>(
            find.descendant(
              of: incoming,
              matching: find.byType(SizeTransition),
            ),
          )
          .sizeFactor
          .value,
      lessThan(1),
    );
    expect(find.text('older'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(OutgoingMessageEntrance), findsNothing);
    expect(find.text('new note'), findsOneWidget);
  });

  testWidgets('the first sent message enters after welcome', (tester) async {
    final messages = FakeMessageRepository();
    final container = await tester.pumpApp(messages: messages);
    await tester.enterText(composerField(), '周末想去爬山');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(container.read(composerControllerProvider).lastSentMessageId, 1);
    expect(container.read(chatFeedProvider), isA<AsyncData<ChatFeed>>());
    expect(find.byType(WelcomeTimeline), findsNothing);
    expect(find.byType(OutgoingMessageEntrance), findsOneWidget);
    expect(find.text('周末想去爬山'), findsOneWidget);

    expect(
      find.ancestor(
        of: find.text('周末想去爬山'),
        matching: find.byType(OutgoingMessageEntrance),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(messages.added.single.text, '周末想去爬山');
    expect(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: find.text('周末想去爬山'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<EditableText>(composerField()).controller.text,
      isEmpty,
    );
  });

  testWidgets('quick successive sends each enter once', (tester) async {
    var tick = 0;
    await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [testMessage(1, 'older')],
        clock: () => kTestNow.add(Duration(seconds: tick++)),
      ),
    );

    await tester.enterText(composerField(), 'one');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(OutgoingMessageEntrance), findsOneWidget);

    await tester.enterText(composerField(), 'two');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(OutgoingMessageEntrance), findsNWidgets(2));
    expect(find.text('older'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(OutgoingMessageEntrance), findsNothing);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('an image-only send uses the same entrance', (tester) async {
    final container = await tester.pumpApp(
      overrides: [imagePickerProvider.overrideWithValue(_SingleImagePicker())],
      messages: FakeMessageRepository(seed: [testMessage(1, 'older')]),
    );
    await tester.runAsync(
      () => container.read(composerControllerProvider.notifier).pickImage(),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.ancestor(
        of: find.byType(MessageImageStack).last,
        matching: find.byType(OutgoingMessageEntrance),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.byType(OutgoingMessageEntrance), findsNothing);
  });

  testWidgets('sending while reading older notes returns to the newest row', (
    tester,
  ) async {
    await tester.pumpApp(
      messages: FakeMessageRepository(
        seed: [for (var id = 1; id <= 40; id++) testMessage(id, 'Note $id')],
        clock: () => kTestNow.add(const Duration(hours: 1)),
      ),
    );
    final timeline = find.descendant(
      of: find.byType(ChatPage),
      matching: find.byType(ListView),
    );
    final scrollable = find.descendant(
      of: timeline,
      matching: find.byType(Scrollable),
    );
    await tester.drag(timeline, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );

    await tester.enterText(composerField(), 'newest');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.chat.send));
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      closeTo(0, 0.1),
    );
    expect(find.text('newest'), findsOneWidget);
  });
}
