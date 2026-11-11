import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.t.me.title,
      body: const SizedBox.shrink(),
    );
  }
}
