import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/platform/external_browser.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../gen/i18n/strings.g.dart';

Future<void> openMessageLink(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final result = await ref.read(externalBrowserProvider).open(url).run();
  if (!context.mounted || result.isRight()) return;
  AppToast.show(
    context,
    message: context.t.chat.openLinkFailed,
    type: GlassToastType.error,
  );
}
