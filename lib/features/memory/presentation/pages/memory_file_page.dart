import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/memory_data_providers.dart';
import '../../domain/models/memory.dart';
import '../providers/memory_providers.dart';

/// Read-only view of one memory file, rendered as markdown.
class MemoryFilePage extends ConsumerWidget {
  const MemoryFilePage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(memoryFileProvider(path));
    final t = context.t;
    final title = switch (file) {
      AsyncData(value: Some(:final value)) => memoryTitle(
        value.path,
        value.content,
      ),
      _ => path,
    };
    return AppPageScaffold(
      title: title,
      leading: GlassIconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        semanticLabel: t.common.close,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        if (file case AsyncData(value: Some(:final value)))
          GlassIconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            semanticLabel: t.memory.more,
            onPressed: () => _showActions(context, ref, value.path),
          ),
      ],
      body: switch (file) {
        AsyncData(value: Some(:final value)) => _MarkdownBody(
          content: value.content,
        ),
        AsyncData(value: None()) || AsyncError() => EmptyState(
          icon: Icons.find_in_page_outlined,
          label: t.memory.missing,
        ),
        AsyncLoading() => const Skeletonizer(
          child: _MarkdownBody(content: '# Placeholder\n\nLoading content…'),
        ),
      },
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    MemoryPath memoryPath,
  ) {
    final t = context.t;
    final navigator = Navigator.of(context);
    // The sheet dismisses itself after any action; handlers must not pop it.
    return showGlassActionSheet<void>(
      context: context,
      title: memoryPath.value,
      cancelLabel: t.common.cancel,
      actions: [
        GlassActionSheetAction(
          label: t.common.delete,
          icon: const Icon(Icons.delete_outline_rounded),
          style: GlassActionSheetStyle.destructive,
          onPressed: () async {
            unawaited(HapticFeedback.heavyImpact());
            await ref.read(memoryRepositoryProvider).delete(memoryPath).run();
            await navigator.maybePop();
          },
        ),
      ],
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppPageInsets.of(context),
      children: [
        GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          padding: const EdgeInsets.all(AppSpacing.lg),
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
          child: SmoothMarkdown(
            data: content,
            selectable: true,
            styleSheet: AppMarkdownTheme.of(context),
          ),
        ),
      ],
    );
  }
}
