import 'package:flutter_test/flutter_test.dart';
import 'package:luthor/luthor.dart' hide Validator;
import 'package:luthor/luthor.dart' as lu show Validator;
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/forms/luthor_validator.dart';

void main() {
  group('luthorValidator', () {
    FormControl<T> control<T>(lu.Validator<Object?> schema, [T? value]) =>
        FormControl<T>(value: value, validators: [luthorValidator(schema)]);

    test('passes valid values', () {
      expect(
        control(l.string().url().required(), 'https://a.dev').valid,
        isTrue,
      );
    });

    test('reports the Luthor issue code as the error key', () {
      expect(control(l.string().url().required(), 'nope').errors.keys, [
        'invalidUrl',
      ]);
      expect(control<int>(l.int().min(10).required(), 3).errors.keys, [
        'tooSmall',
      ]);
    });

    test('treats blank text as missing so required catches it', () {
      expect(control(l.string().required(), '   ').errors.keys, ['required']);
      expect(control<String>(l.string().required()).errors.keys, ['required']);
    });

    test('optional fields accept blank text', () {
      expect(control(l.string().url(), '').valid, isTrue);
    });

    test('trims before validating', () {
      expect(control(l.string().max(3).required(), '  abc  ').valid, isTrue);
    });

    test('re-validates as the value changes', () {
      final c = control(l.string().required(), '');
      expect(c.invalid, isTrue);
      c.value = 'ok';
      expect(c.valid, isTrue);
    });
  });
}
