import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/ai_settings.dart';

/// Network boundary for checking a configured model without persisting output.
abstract interface class ModelProbe {
  TaskEither<AppFailure, Unit> test(
    ProviderConfig provider,
    String apiKey,
    ModelConfig model,
  );
}
