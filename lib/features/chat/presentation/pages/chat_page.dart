import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.t.chat.title,
      body: EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        label: context.t.chat.empty,
      ),
    );
  }
}
