import 'package:flutter/material.dart';

import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';

extension ApiFormatLabel on ApiFormat {
  String label(BuildContext context) {
    final f = context.t.settings.format;
    return switch (this) {
      ApiFormat.chatCompletions => f.chatCompletions,
      ApiFormat.responses => f.responses,
      ApiFormat.messages => f.messages,
    };
  }
}

extension ReasoningEffortLabel on ReasoningEffort {
  String label(BuildContext context) {
    final e = context.t.settings.effort;
    return switch (this) {
      ReasoningEffort.minimal => e.minimal,
      ReasoningEffort.low => e.low,
      ReasoningEffort.medium => e.medium,
      ReasoningEffort.high => e.high,
      ReasoningEffort.xhigh => e.xhigh,
    };
  }
}
