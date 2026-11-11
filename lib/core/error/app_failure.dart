import 'package:freezed_annotation/freezed_annotation.dart';

part '../../gen/core/error/app_failure.freezed.dart';

/// The single error algebra crossing layer boundaries. Data sources translate
/// platform exceptions into one of these variants; presentation maps each
/// variant to localized copy with an exhaustive `switch`.
@freezed
sealed class AppFailure with _$AppFailure {
  const AppFailure._();

  const factory AppFailure.network({required String message, int? statusCode}) =
      NetworkFailure;

  const factory AppFailure.database({required String message}) =
      DatabaseFailure;

  const factory AppFailure.validation({required String message}) =
      ValidationFailure;

  const factory AppFailure.permissionDenied({
    required String permission,
    @Default(false) bool permanently,
  }) = PermissionFailure;

  const factory AppFailure.unexpected({
    required Object error,
    StackTrace? stackTrace,
  }) = UnexpectedFailure;

  /// Adapter for `TaskEither.tryCatch` / `Either.tryCatch`: keeps failures that
  /// were already classified and wraps everything else as [UnexpectedFailure].
  static AppFailure fromError(Object error, StackTrace stackTrace) =>
      switch (error) {
        final AppFailure failure => failure,
        _ => AppFailure.unexpected(error: error, stackTrace: stackTrace),
      };

  /// Validation message for an AI provider without a stored API key; the UI
  /// turns it into "add a key" guidance instead of a generic error.
  static const missingApiKey = 'missing api key';

  /// Validation message when AI mode has no enabled model to use.
  static const noModel = 'no model configured';

  bool get isRetryable => switch (this) {
    NetworkFailure() => true,
    DatabaseFailure() => false,
    ValidationFailure() => false,
    PermissionFailure(:final permanently) => !permanently,
    UnexpectedFailure() => false,
  };
}
