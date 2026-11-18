import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';

import '../../../../support/app_widget_tester.dart';

Message testMessage(
  int id,
  String text, {
  MessageAuthor author = MessageAuthor.me,
  DateTime? at,
  List<String> images = const [],
}) => Message(
  id: id,
  createdAt: at ?? kTestNow.subtract(Duration(minutes: 10 - id)),
  author: author,
  text: text,
  images: images,
);

Finder composerField() => find.descendant(
  of: find.byType(ChatComposer),
  matching: find.byType(EditableText),
);
