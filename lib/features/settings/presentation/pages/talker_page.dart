import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/logger/talker_provider.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../widgets/settings_back_button.dart';

class TalkerPage extends ConsumerWidget {
  const TalkerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TalkerScreen(
    talker: ref.watch(talkerProvider),
    appBarTitle: context.t.me.logs,
    appBarLeading: const SettingsBackButton(),
    theme: TalkerScreenTheme.fromTheme(Theme.of(context)),
  );
}
