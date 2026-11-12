import '../models/ai_settings.dart';

/// Pure transformations of [AiSettings]; the controller persists the result.
extension AiSettingsEdits on AiSettings {
  AiSettings upsertProvider(ProviderConfig provider) {
    final exists = providers.any((p) => p.id == provider.id);
    return copyWith(
      providers: exists
          ? [for (final p in providers) p.id == provider.id ? provider : p]
          : [...providers, provider],
    );
  }

  /// Drops the provider, its models, and the active selection if it pointed
  /// at one of them.
  AiSettings removeProvider(String providerId) => copyWith(
    providers: [...providers.where((p) => p.id != providerId)],
    models: [...models.where((m) => m.providerId != providerId)],
    activeModel: activeModel?.providerId == providerId ? null : activeModel,
  );

  /// Replaces a provider's model list with [fetchedIds], keeping the
  /// configuration of models that are still offered. Models that vanished
  /// upstream are dropped unless the user enabled them (a temporary listing
  /// glitch must not silently wipe a working setup).
  AiSettings mergeFetchedModels(String providerId, List<String> fetchedIds) {
    final existing = {
      for (final m in models.where((m) => m.providerId == providerId))
        m.modelId: m,
    };
    final fetched = fetchedIds.toSet();
    final ids = fetched.toList()..sort();
    final merged = [
      for (final id in ids)
        existing[id] ?? ModelConfig(providerId: providerId, modelId: id),
      for (final kept in existing.values)
        if (kept.enabled && !fetched.contains(kept.modelId)) kept,
    ];
    return copyWith(
      models: [...models.where((m) => m.providerId != providerId), ...merged],
    );
  }

  /// Saves [model], adding it if unknown. Enabling the first model makes it
  /// active so AI mode works without another trip to settings.
  AiSettings upsertModel(ModelConfig model) {
    final exists = models.any((m) => m.ref == model.ref);
    final next = copyWith(
      models: exists
          ? [for (final m in models) m.ref == model.ref ? model : m]
          : [...models, model],
    );
    final activeStillValid = next.enabledModels.any(
      (m) => m.ref == next.activeModel,
    );
    return activeStillValid
        ? next
        : next.copyWith(activeModel: next.enabledModels.firstOrNull?.ref);
  }

  /// Catalog entries remain available after removal, so they can be added
  /// again without another network request.
  AiSettings addModels(String providerId, Set<String> modelIds) {
    if (modelIds.isEmpty) return this;
    final next = copyWith(
      models: [
        for (final model in models)
          model.providerId == providerId && modelIds.contains(model.modelId)
              ? model.copyWith(enabled: true)
              : model,
      ],
    );
    final activeStillValid = next.enabledModels.any(
      (model) => model.ref == next.activeModel,
    );
    return activeStillValid
        ? next
        : next.copyWith(activeModel: next.enabledModels.firstOrNull?.ref);
  }

  AiSettings removeModel(ModelRef ref) {
    final model = models.where((candidate) => candidate.ref == ref).firstOrNull;
    return model == null ? this : upsertModel(model.copyWith(enabled: false));
  }

  AiSettings selectModel(ModelRef ref) {
    final enabled = enabledModels.any((m) => m.ref == ref);
    return enabled ? copyWith(activeModel: ref) : this;
  }

  AiSettings withHistoryTurns(int turns) => copyWith(
    historyTurns: turns.clamp(
      AiSettings.minHistoryTurns,
      AiSettings.maxHistoryTurns,
    ),
  );
}
