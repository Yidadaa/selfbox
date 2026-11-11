import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/primary_button.dart';
import '../widgets/settings_labels.dart';

/// Create (no [id]) or edit a provider, and manage its models.
class ProviderPage extends ConsumerWidget {
  const ProviderPage({this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final settings = ref.watch(aiSettingsProvider);
    final keyStored = id == null
        ? const AsyncData(false)
        : ref.watch(hasApiKeyProvider(id));
    final t = context.t;

    return switch ((settings, keyStored)) {
      (AsyncData(value: final s), AsyncData(value: final stored)) =>
        id != null && s.providerOf(id) == null
            ? AppPageScaffold(
                title: t.settings.provider.title,
                leading: const _BackButton(),
                body: EmptyState(
                  icon: Icons.dns_outlined,
                  label: t.settings.errors.generic,
                ),
              )
            : _ProviderForm(
                existing: id == null ? null : s.providerOf(id),
                keyStored: stored,
              ),
      (AsyncError(), _) || (_, AsyncError()) => AppPageScaffold(
        title: t.settings.provider.title,
        leading: const _BackButton(),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          label: t.settings.errors.generic,
        ),
      ),
      _ => AppPageScaffold(
        title: t.settings.provider.title,
        leading: const _BackButton(),
        body: const Skeletonizer(child: SizedBox.expand()),
      ),
    };
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    semanticLabel: context.t.common.close,
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

class _ProviderForm extends HookConsumerWidget {
  const _ProviderForm({required this.existing, required this.keyStored});

  final ProviderConfig? existing;
  final bool keyStored;

  static const _name = 'name';
  static const _format = 'format';
  static const _baseUrl = 'baseUrl';
  static const _apiKey = 'apiKey';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final existing = this.existing;
    final id = useMemoized(() => existing?.id ?? const Uuid().v4());
    final saving = useState(false);
    final form = useMemoized(
      () => FormGroup({
        _name: FormControl<String>(
          value: existing?.name ?? '',
          validators: [luthorValidator(AiSettingsSchema.providerName)],
        ),
        _format: FormControl<ApiFormat>(
          value: existing?.format ?? ApiFormat.chatCompletions,
        ),
        _baseUrl: FormControl<String>(
          value: existing?.baseUrl ?? ApiFormat.chatCompletions.defaultBaseUrl,
          validators: [luthorValidator(AiSettingsSchema.baseUrl)],
        ),
        _apiKey: FormControl<String>(
          value: '',
          validators: [
            // A stored key may be kept by leaving the field blank.
            if (!keyStored) luthorValidator(AiSettingsSchema.apiKey),
          ],
        ),
      }),
    );
    useEffect(() => form.dispose, [form]);

    Future<void> save() async {
      form.markAllAsTouched();
      if (!form.valid || saving.value) return;
      final format = form.control(_format).value as ApiFormat;
      final config = ProviderConfig(
        id: id,
        name: (form.control(_name).value as String).trim(),
        format: format,
        baseUrl: (form.control(_baseUrl).value as String).trim(),
      );
      saving.value = true;
      final service = ref.read(aiSettingsServiceProvider);
      final saved = await service
          .saveProvider(
            config,
            apiKey: form.control(_apiKey).value as String? ?? '',
          )
          .run();
      // New providers fetch their model list right away; that is the next
      // thing anyone does after adding one.
      final fetched = existing == null && saved.isRight()
          ? await service.refreshModels(id).run()
          : null;
      if (!context.mounted) return;
      saving.value = false;
      ref.invalidate(hasApiKeyProvider(id));
      showOutcome(
        context,
        failure:
            saved.getLeft().toNullable() ?? fetched?.getLeft().toNullable(),
        success: t.common.saved,
      );
      if (saved.isRight() && existing == null) {
        ProviderRoute(id: id).pushReplacement(context);
      } else {
        form.control(_apiKey).reset(value: '');
      }
    }

    return AppPageScaffold(
      title: existing?.name ?? t.settings.provider.newTitle,
      leading: const _BackButton(),
      actions: [
        if (existing != null)
          GlassIconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            semanticLabel: t.common.more,
            onPressed: () => _showActions(context, ref, existing),
          ),
      ],
      body: ReactiveForm(
        formGroup: form,
        child: ListView(
          padding: AppPageInsets.of(context),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassReactiveTextField<String>(
                    formControlName: _name,
                    label: t.settings.provider.name,
                  ),
                  const Gap(AppSpacing.md),
                  _FormatPicker(
                    form: form,
                    formatControl: _format,
                    baseUrlControl: _baseUrl,
                  ),
                  const Gap(AppSpacing.md),
                  GlassReactiveTextField<String>(
                    formControlName: _baseUrl,
                    label: t.settings.provider.baseUrl,
                    keyboardType: TextInputType.url,
                  ),
                  const Gap(AppSpacing.md),
                  GlassReactiveTextField<String>(
                    formControlName: _apiKey,
                    label: t.settings.provider.apiKey,
                    placeholder: keyStored
                        ? t.settings.provider.apiKeyKept
                        : null,
                    obscureText: true,
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            PrimaryButton(
              label: t.common.save,
              busy: saving.value,
              onTap: save,
            ),
            if (existing != null) ...[
              const Gap(AppSpacing.xl),
              _ModelsSection(providerId: existing.id),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    ProviderConfig provider,
  ) {
    final navigator = Navigator.of(context);
    // The sheet dismisses itself after any action; handlers must not pop it.
    return showGlassActionSheet<void>(
      context: context,
      title: provider.name,
      cancelLabel: context.t.common.cancel,
      actions: [
        GlassActionSheetAction(
          label: context.t.settings.provider.delete,
          icon: const Icon(Icons.delete_outline_rounded),
          style: GlassActionSheetStyle.destructive,
          onPressed: () async {
            await ref
                .read(aiSettingsServiceProvider)
                .deleteProvider(provider.id)
                .run();
            await navigator.maybePop();
          },
        ),
      ],
    );
  }
}

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({
    required this.form,
    required this.formatControl,
    required this.baseUrlControl,
  });

  final FormGroup form;
  final String formatControl;
  final String baseUrlControl;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs),
          child: Text(
            context.t.settings.provider.format,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: glass.foregroundMuted),
          ),
        ),
        const Gap(AppSpacing.xs),
        ReactiveValueListenableBuilder<ApiFormat>(
          formControlName: formatControl,
          builder: (context, control, _) => GlassSegmentedControl(
            selectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            unselectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.glass.foregroundMuted),
            selectedIndex: ApiFormat.values.indexOf(
              control.value ?? ApiFormat.chatCompletions,
            ),
            segments: [
              for (final format in ApiFormat.values)
                GlassSegment(label: format.label(context)),
            ],
            onSegmentSelected: (index) {
              final previous = control.value;
              final next = ApiFormat.values[index];
              control.value = next;
              // Swap the URL only while it is still the previous default.
              final url = form.control(baseUrlControl);
              if (url.value == previous?.defaultBaseUrl) {
                url.value = next.defaultBaseUrl;
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ModelsSection extends HookConsumerWidget {
  const _ModelsSection({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final fetching = useState(false);
    final models = ref.watch(
      aiSettingsProvider.select(
        (s) => s.whenData((v) => v.modelsOf(providerId)).value ?? const [],
      ),
    );

    Future<void> fetch() async {
      fetching.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .refreshModels(providerId)
          .run();
      if (!context.mounted) return;
      fetching.value = false;
      showOutcome(
        context,
        failure: result.getLeft().toNullable(),
        success: t.settings.provider.fetched,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassGroupedSection(
          margin: AppInsets.section,
          surfaceStyle: GlassSurfaceStyle.solid,
          header: SectionHeader(t.settings.provider.models),
          children: [
            if (models.isEmpty)
              AppListTile(
                icon: Icons.inventory_2_outlined,
                title: t.settings.provider.noModels,
              ),
            for (final model in models)
              AppListTile(
                title: model.modelId,
                trailing: GlassSwitch(
                  value: model.enabled,
                  onChanged: (enabled) => ref
                      .read(aiSettingsServiceProvider)
                      .saveModel(model.copyWith(enabled: enabled))
                      .run(),
                ),
                onTap: () => ModelRoute(
                  provider: providerId,
                  model: model.modelId,
                ).push<void>(context),
              ),
          ],
        ),
        const Gap(AppSpacing.md),
        PrimaryButton(
          label: t.settings.provider.fetchModels,
          icon: Icons.sync_rounded,
          busy: fetching.value,
          onTap: fetch,
        ),
      ],
    );
  }
}
