import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../../model_test_providers.dart';
import '../../domain/models/ai_settings.dart';

class ModelTestControl extends HookConsumerWidget {
  const ModelTestControl({required this.model, super.key});

  final ModelConfig model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useState<({bool loading, Either<AppFailure, Unit>? result})>((
      loading: false,
      result: null,
    ));

    Future<void> test() async {
      if (state.value.loading) return;
      state.value = (loading: true, result: null);
      final result = await ref
          .read(modelTestServiceProvider)
          .test(model.ref)
          .run();
      if (!context.mounted) return;
      state.value = (loading: false, result: result);
    }

    final result = state.value.result;
    final failure = result?.getLeft().toNullable();
    final succeeded = result?.isRight() ?? false;
    final color = succeeded
        ? context.glass.accent
        : context.glass.dialogDestructive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppActionButton(
          key: const ValueKey('test-model-button'),
          onPressed: state.value.loading ? null : test,
          icon: state.value.loading ? null : Icons.play_arrow_rounded,
          label: state.value.loading
              ? context.t.settings.model.testing
              : context.t.settings.model.testModel,
          busy: state.value.loading,
        ),
        if (result != null) ...[
          const Gap(AppSpacing.xs),
          Row(
            children: [
              Icon(
                succeeded
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: color,
                size: AppSizes.iconMd,
              ),
              const Gap(AppSpacing.xs),
              Expanded(
                child: Text(
                  succeeded
                      ? context.t.settings.model.available
                      : context.t.settings.model.testFailed,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
          if (failure != null) ...[
            const Gap(AppSpacing.xxs),
            Text(
              failureMessage(context, failure),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.glass.foregroundMuted),
            ),
          ],
        ],
      ],
    );
  }
}
