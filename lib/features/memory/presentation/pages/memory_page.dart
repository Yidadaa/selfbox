import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';

class MemoryPage extends StatelessWidget {
  const MemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.t.memory.title,
      body: EmptyState(
        icon: Icons.auto_awesome_outlined,
        label: context.t.memory.empty,
      ),
    );
  }
}
