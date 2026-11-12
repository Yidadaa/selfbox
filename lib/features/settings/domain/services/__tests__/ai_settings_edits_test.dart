import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/services/ai_settings_edits.dart';

const _openai = ProviderConfig(
  id: 'p1',
  name: 'OpenAI',
  format: ApiFormat.responses,
  baseUrl: 'https://api.openai.com/v1',
);
const _anthropic = ProviderConfig(
  id: 'p2',
  name: 'Anthropic',
  format: ApiFormat.messages,
  baseUrl: 'https://api.anthropic.com/v1',
);

ModelConfig _m(String provider, String id, {bool enabled = false}) =>
    ModelConfig(providerId: provider, modelId: id, enabled: enabled);

void main() {
  group('AiSettingsEdits', () {
    test('upsertProvider adds then replaces by id', () {
      final added = const AiSettings().upsertProvider(_openai);
      expect(added.providers, [_openai]);

      final renamed = added.upsertProvider(_openai.copyWith(name: 'Mine'));
      expect(renamed.providers.single.name, 'Mine');
    });

    test('removeProvider drops its models and clears a dangling selection', () {
      final settings = AiSettings(
        providers: const [_openai, _anthropic],
        models: [_m('p1', 'a', enabled: true), _m('p2', 'b', enabled: true)],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'a'),
      );

      final next = settings.removeProvider('p1');
      expect(next.providers, [_anthropic]);
      expect(next.models.map((m) => m.modelId), ['b']);
      expect(next.activeModel, isNull);
      expect(next.resolvedModel?.modelId, 'b');
    });

    test('mergeFetchedModels keeps config for models still offered', () {
      final configured = _m(
        'p1',
        'gpt-a',
        enabled: true,
      ).copyWith(maxOutputTokens: 4096, supportsImages: true);
      final settings = AiSettings(models: [configured, _m('p2', 'other')]);

      final next = settings.mergeFetchedModels('p1', ['gpt-b', 'gpt-a']);
      expect(next.modelsOf('p1').map((m) => m.modelId), ['gpt-a', 'gpt-b']);
      expect(next.modelsOf('p1').first, configured);
      expect(next.modelsOf('p1').last.enabled, isFalse);
      expect(next.modelsOf('p2'), hasLength(1));
    });

    test('mergeFetchedModels drops vanished models unless enabled', () {
      final settings = AiSettings(
        models: [_m('p1', 'kept', enabled: true), _m('p1', 'gone')],
      );
      final next = settings.mergeFetchedModels('p1', ['new']);
      expect(next.modelsOf('p1').map((m) => m.modelId), ['new', 'kept']);
    });

    test('mergeFetchedModels de-duplicates ids', () {
      final next = const AiSettings().mergeFetchedModels('p1', ['a', 'a']);
      expect(next.models, hasLength(1));
    });

    test('enabling the first model makes it active', () {
      final settings = AiSettings(models: [_m('p1', 'a'), _m('p1', 'b')]);
      final next = settings.upsertModel(_m('p1', 'b', enabled: true));

      expect(next.activeModel, const ModelRef(providerId: 'p1', modelId: 'b'));
    });

    test(
      'batch add enables only fetched matches and keeps an active model',
      () {
        final settings = AiSettings(
          models: [_m('p1', 'a'), _m('p1', 'b'), _m('p2', 'b', enabled: true)],
          activeModel: const ModelRef(providerId: 'p2', modelId: 'b'),
        );

        final next = settings.addModels('p1', {'b', 'missing'});
        expect(
          next.modelsOf('p1').where((m) => m.enabled).map((m) => m.modelId),
          ['b'],
        );
        expect(next.modelsOf('p2').single.enabled, isTrue);
        expect(next.activeModel, settings.activeModel);
        expect(next.addModels('p1', {'b'}), next);
      },
    );

    test('removing a model hides it but keeps its fetched configuration', () {
      final configured = _m(
        'p1',
        'a',
        enabled: true,
      ).copyWith(maxInputTokens: 64000);
      final settings = AiSettings(
        models: [configured, _m('p1', 'b', enabled: true)],
        activeModel: configured.ref,
      );

      final next = settings.removeModel(configured.ref);
      expect(next.modelsOf('p1').first.enabled, isFalse);
      expect(next.modelsOf('p1').first.maxInputTokens, 64000);
      expect(next.activeModel?.modelId, 'b');
      expect(next.addModels('p1', {'a'}).modelsOf('p1').first.enabled, isTrue);
    });

    test('disabling the active model falls back to another enabled one', () {
      final settings = AiSettings(
        models: [_m('p1', 'a', enabled: true), _m('p1', 'b', enabled: true)],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'a'),
      );
      final next = settings.upsertModel(_m('p1', 'a'));
      expect(next.activeModel?.modelId, 'b');

      final none = next.upsertModel(_m('p1', 'b'));
      expect(none.activeModel, isNull);
      expect(none.resolvedModel, isNull);
    });

    test('selectModel ignores models that are not enabled', () {
      final settings = AiSettings(
        models: [_m('p1', 'a', enabled: true), _m('p1', 'b')],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'a'),
      );
      const b = ModelRef(providerId: 'p1', modelId: 'b');
      expect(settings.selectModel(b).activeModel?.modelId, 'a');
    });

    test('withHistoryTurns clamps to the allowed range', () {
      expect(const AiSettings().withHistoryTurns(-3).historyTurns, 0);
      expect(const AiSettings().withHistoryTurns(500).historyTurns, 100);
      expect(const AiSettings().withHistoryTurns(12).historyTurns, 12);
    });
  });

  group('AiSettings', () {
    test('round-trips through JSON', () {
      final settings = AiSettings(
        providers: const [_openai],
        models: [
          _m('p1', 'a', enabled: true).copyWith(
            supportsReasoning: true,
            reasoningEffort: ReasoningEffort.high,
          ),
        ],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'a'),
        historyTurns: 8,
      );
      expect(AiSettings.fromJson(settings.toJson()), settings);
    });

    test('defaults are usable on an empty document', () {
      final settings = AiSettings.fromJson(const {});
      expect(settings.historyTurns, AiSettings.defaultHistoryTurns);
      expect(settings.resolvedModel, isNull);
    });

    test('resolvedModel ignores a stale active reference', () {
      final settings = AiSettings(
        models: [_m('p1', 'a', enabled: true)],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'gone'),
      );
      expect(settings.resolvedModel?.modelId, 'a');
    });

    test('api formats default to their vendor endpoints', () {
      expect(ApiFormat.messages.defaultBaseUrl, contains('anthropic'));
      expect(ApiFormat.chatCompletions.defaultBaseUrl, contains('openai'));
    });
  });

  group('AiSettingsSchema', () {
    test('base URL must be http(s)', () {
      expect(
        AiSettingsSchema.baseUrl.validate('https://example.com/v1').isValid,
        isTrue,
      );
      expect(AiSettingsSchema.baseUrl.validate('ftp://x.com').isValid, isFalse);
      expect(AiSettingsSchema.baseUrl.validate('not a url').isValid, isFalse);
      expect(AiSettingsSchema.baseUrl.validate(null).isValid, isFalse);
    });

    test('token budgets reject zero, negatives and absurd values', () {
      expect(AiSettingsSchema.outputTokens.validate(4096).isValid, isTrue);
      expect(AiSettingsSchema.outputTokens.validate(0).isValid, isFalse);
      expect(AiSettingsSchema.inputTokens.validate(-1).isValid, isFalse);
      expect(
        AiSettingsSchema.inputTokens
            .validate(AiSettingsSchema.maxTokens + 1)
            .isValid,
        isFalse,
      );
    });

    test('provider names must be non-empty and short', () {
      expect(AiSettingsSchema.providerName.validate('').isValid, isFalse);
      expect(
        AiSettingsSchema.providerName
            .validate('x' * (AiSettingsSchema.maxNameLength + 1))
            .isValid,
        isFalse,
      );
    });
  });
}
