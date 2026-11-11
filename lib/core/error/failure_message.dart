import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../gen/i18n/strings.g.dart';
import 'app_failure.dart';

/// Short, user-facing copy for a failure. Details stay in the logs.
String failureMessage(BuildContext context, AppFailure failure) {
  final e = context.t.settings.errors;
  return switch (failure) {
    NetworkFailure(statusCode: 401 || 403) => e.auth,
    NetworkFailure() => e.network,
    ValidationFailure(message: AppFailure.missingApiKey) => e.missingKey,
    ValidationFailure(message: AppFailure.noModel) => e.noModel,
    ValidationFailure() ||
    DatabaseFailure() ||
    PermissionFailure() => e.generic,
    UnexpectedFailure() => e.generic,
  };
}

/// Toast for the outcome of a user action, with matching haptics.
void showOutcome(BuildContext context, {AppFailure? failure, String? success}) {
  if (failure != null) {
    HapticFeedback.heavyImpact();
    GlassToast.show(
      context,
      message: failureMessage(context, failure),
      type: GlassToastType.error,
    );
    return;
  }
  if (success == null) return;
  HapticFeedback.lightImpact();
  GlassToast.show(context, message: success);
}
