import 'package:luthor/luthor.dart' as lu;
import 'package:reactive_forms/reactive_forms.dart';

/// Adapts a Luthor schema to a reactive_forms validator, so each rule is
/// written once in the domain and enforced by the form.
///
/// The error key is the Luthor issue code (`required`, `invalidUrl`,
/// `tooSmall`, …); the UI maps codes to localized copy.
Validator<dynamic> luthorValidator(lu.Validator<Object?> schema) =>
    Validators.delegate((control) {
      final value = switch (control.value) {
        final String text when text.trim().isEmpty => null,
        final String text => text.trim(),
        final other => other,
      };
      return switch (schema.validate(value)) {
        lu.ValidationSuccess() => null,
        lu.ValidationFailure(:final issues) => {
          issues.first.code.name: issues.first.params,
        },
      };
    });
