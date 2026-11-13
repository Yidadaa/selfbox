import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:luthor/luthor.dart' as lu;
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_markdown_builders.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/widgets/primary_button.dart';
import '../../../settings/presentation/widgets/settings_back_button.dart';
import '../../data/memory_data_providers.dart';
import '../../domain/models/memory.dart';
import '../providers/memory_providers.dart';

class MemoryEditorPage extends ConsumerWidget {
  const MemoryEditorPage({this.path, super.key});

  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = this.path;
    final file = path == null ? null : ref.watch(memoryFileProvider(path));
    return AppPageScaffold(
      title: path == null ? context.t.memory.add : context.t.memory.edit,
      leading: const SettingsBackButton(),
      body: switch (file) {
        null => const _MemoryEditor(),
        AsyncData(value: Some(:final value)) => _MemoryEditor(file: value),
        AsyncData(value: None()) ||
        AsyncError() => EmptyState(label: context.t.memory.missing),
        AsyncLoading() => const SizedBox.expand(),
      },
    );
  }
}

class _MemoryEditor extends HookConsumerWidget {
  const _MemoryEditor({this.file});

  final MemoryFile? file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = useMemoized(() => file, [file?.path.value]);
    final busy = useState(false);
    final form = useMemoized(
      () => FormGroup({
        'name': FormControl<String>(
          value: source?.path.value ?? '',
          validators: [
            luthorValidator(lu.l.string().min(1).max(160).required()),
          ],
        ),
        'content': FormControl<String>(
          value: source?.content ?? '',
          validators: [luthorValidator(lu.l.string().min(1).required())],
        ),
      }),
      [source?.path.value],
    );
    final editor = useMemoized(
      () => MarkdownEditorController(text: source?.content ?? ''),
      [source?.path.value],
    );
    useEffect(() {
      return () {
        form.dispose();
        editor.dispose();
      };
    }, [form, editor]);

    Future<void> save() async {
      form.control('content').value = editor.text;
      form.markAllAsTouched();
      if (!form.valid || busy.value) return;
      final name = (form.control('name').value as String).trim();
      final rawPath = name.endsWith('.md') ? name : '$name.md';
      final valid = MemoryPath.parse(rawPath);
      if (valid case Left()) {
        GlassToast.show(context, message: context.t.memory.invalidName);
        return;
      }
      final path = valid.toNullable();
      if (path == null) return;
      busy.value = true;
      final repository = ref.read(memoryRepositoryProvider);
      final result =
          await (source == null
                  ? repository.create(path, editor.text)
                  : repository.replace(
                      source.path,
                      editor.text,
                      expectedContent: source.content,
                    ))
              .run();
      if (!context.mounted) return;
      busy.value = false;
      if (result.getLeft().toNullable() case final failure?) {
        final message = switch (failure) {
          ValidationFailure(message: 'memory changed while editing') =>
            context.t.memory.changed,
          ValidationFailure() => context.t.memory.exists,
          _ => null,
        };
        if (message == null) {
          showOutcome(context, failure: failure);
        } else {
          GlassToast.show(
            context,
            message: message,
            type: GlassToastType.error,
          );
        }
        return;
      }
      context.pop();
    }

    return ReactiveForm(
      formGroup: form,
      child: ListView(
        padding: AppPageInsets.of(context),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (source == null)
            GlassReactiveTextField<String>(
              formControlName: 'name',
              label: context.t.memory.fileName,
            )
          else
            Text(
              source.path.value,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          const Gap(AppSpacing.lg),
          Text(
            context.t.memory.content,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Gap(AppSpacing.xs),
          Material(
            type: MaterialType.transparency,
            child: SmoothMarkdownEditor(
              builderRegistry: appMarkdownBuilders(),
              controller: editor,
              initialMode: MarkdownEditorMode.source,
              showToolbar: false,
              enableSlashCommands: false,
              height: MediaQuery.sizeOf(context).height * 0.5,
              textStyle: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(height: 1.5),
              styleSheet: AppMarkdownTheme.of(context),
              onChanged: (value) => form.control('content').value = value,
            ),
          ),
          ReactiveValueListenableBuilder<String>(
            formControlName: 'content',
            builder: (context, control, _) => control.invalid && control.touched
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(context.t.forms.required),
                  )
                : const SizedBox.shrink(),
          ),
          const Gap(AppSpacing.lg),
          PrimaryButton(
            label: context.t.common.save,
            busy: busy.value,
            onTap: save,
          ),
        ],
      ),
    );
  }
}
