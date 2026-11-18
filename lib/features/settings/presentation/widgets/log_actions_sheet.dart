import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../gen/i18n/strings.g.dart';

Future<void> showLogActions(
  BuildContext context, {
  required Talker talker,
  required List<TalkerData> filtered,
  required bool expanded,
  required VoidCallback onReverse,
  required VoidCallback onExpand,
  required VoidCallback onClear,
}) {
  final labels = context.t;
  Future<void> copy(List<TalkerData> data) async {
    await Clipboard.setData(ClipboardData(text: data.getFormattedText()));
    if (context.mounted) AppToast.show(context, message: labels.logs.copied);
  }

  return showDialog<void>(
    context: context,
    animationStyle: AppMotion.style(context),
    builder: (_) => AppActionDialog(
      title: labels.logs.actions,
      cancelLabel: labels.common.cancel,
      actions: [
        AppDialogAction(label: labels.logs.reverse, onPressed: onReverse),
        AppDialogAction(
          label: labels.logs.copyAll,
          onPressed: () => copy(talker.history),
        ),
        AppDialogAction(
          label: labels.logs.copyFiltered,
          onPressed: () => copy(filtered),
        ),
        AppDialogAction(
          label: expanded ? labels.logs.collapse : labels.logs.expand,
          onPressed: onExpand,
        ),
        AppDialogAction(
          label: labels.logs.share,
          onPressed: () => _share(context, talker.history.getFormattedText()),
        ),
        AppDialogAction(
          label: labels.logs.clear,
          destructive: true,
          onPressed: onClear,
        ),
      ],
    ),
  );
}

Future<void> _share(BuildContext context, String text) async {
  final box = context.findRenderObject();
  final origin = box is RenderBox
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final result = await TaskEither.tryCatch(
    () => SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(text)),
            mimeType: 'text/plain',
          ),
        ],
        fileNameOverrides: const ['xiaolan-logs.txt'],
        sharePositionOrigin: origin,
      ),
    ),
    AppFailure.fromError,
  ).run();
  if (context.mounted && result.isLeft()) {
    showOutcome(context, failure: result.getLeft().toNullable());
  }
}
