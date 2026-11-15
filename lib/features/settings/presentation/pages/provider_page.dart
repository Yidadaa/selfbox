import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/provider_credentials_card.dart';
import '../widgets/provider_headers_sheet.dart';
import '../widgets/provider_models_section.dart';

/// Create (no [id]) or edit a provider, and manage its models.
class ProviderPage extends ConsumerWidget {
  const ProviderPage({this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final settings = ref.watch(
      aiSettingsProvider.select(
        (state) => state.whenData(
          (settings) => id == null ? null : settings.providerOf(id),
        ),
      ),
    );
    final keyStored = id == null
        ? const AsyncData(false)
        : ref.watch(hasApiKeyProvider(id));
    final t = context.t;

    return switch ((settings, keyStored)) {
      (AsyncData(value: final s), AsyncData(value: final stored)) =>
        id != null && s == null
            ? AppPageScaffold(
                title: t.settings.provider.title,
                leading: const _BackButton(),
                body: EmptyState(
                  label: t.settings.errors.generic,
                  illustration: BrandArt.error,
                ),
              )
            : _ProviderForm(existing: s, keyStored: stored),
      (AsyncError(), _) || (_, AsyncError()) => AppPageScaffold(
        title: t.settings.provider.title,
        leading: const _BackButton(),
        body: EmptyState(
          label: t.settings.errors.generic,
          illustration: BrandArt.error,
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
    size: AppSizes.minTouchTarget,
    icon: const AppIcon(AppIcons.back),
    quality: AppEffects.qualityOf(context, GlassQuality.standard),
    semanticLabel: context.t.common.close,
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

class _ProviderForm extends HookConsumerWidget {
  const _ProviderForm({required this.existing, required this.keyStored});

  final ProviderConfig? existing;
  final bool keyStored;

  static const _name = ProviderCredentialsCard.name;
  static const _format = ProviderCredentialsCard.format;
  static const _baseUrl = ProviderCredentialsCard.baseUrl;
  static const _apiKey = ProviderCredentialsCard.apiKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final existing = this.existing;
    final id = useMemoized(() => existing?.id ?? const Uuid().v4());
    final saving = useState(false);
    final headers = useState<Map<String, String>>(
      Map<String, String>.of(existing?.headers ?? const {}),
    );
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
        headers: Map.unmodifiable(headers.value),
      );
      saving.value = true;
      final service = ref.read(aiSettingsServiceProvider);
      final saved = await service
          .saveProvider(
            config,
            apiKey: form.control(_apiKey).value as String? ?? '',
          )
          .run();
      // The key must be persisted before the catalog request can use it.
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
            size: AppSizes.minTouchTarget,
            icon: const AppIcon(AppIcons.more),
            quality: AppEffects.qualityOf(context, GlassQuality.standard),
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
            ProviderCredentialsCard(form: form, keyStored: keyStored),
            const Gap(AppSpacing.cardGroup),
            GlassGroupedSection(
              key: const ValueKey('edit-provider-headers'),
              margin: EdgeInsets.zero,
              surfaceStyle: GlassSurfaceStyle.solid,
              shape: LiquidRoundedSuperellipse(
                borderRadius: AppRadius.lg,
                side: AppEffects.solidBorderOf(context),
              ),
              children: [
                AppListTile(
                  title: t.settings.provider.headers,
                  subtitle: headers.value.isEmpty
                      ? t.settings.provider.noHeaders
                      : headers.value.keys.join(', '),
                  icon: AppIcons.api,
                  value: '${headers.value.length}',
                  onTap: () async {
                    final result = await showProviderHeadersSheet(
                      context: context,
                      headers: headers.value,
                    );
                    if (result != null) headers.value = result;
                  },
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            AppPageButton(
              label: t.common.save,
              busy: saving.value,
              onPressed: save,
            ),
            if (existing != null) ...[
              const Gap(AppSpacing.xl),
              ProviderModelsSection(providerId: existing.id),
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
    final t = context.t;
    final navigator = Navigator.of(context);
    return showDialog<void>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (_) => AppConfirmDialog(
        title: provider.name,
        secondaryLabel: t.common.cancel,
        primaryLabel: t.settings.provider.delete,
        destructive: true,
        onPrimary: () async {
          await ref
              .read(aiSettingsServiceProvider)
              .deleteProvider(provider.id)
              .run();
          await navigator.maybePop();
        },
      ),
    );
  }
}
