import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('variants with equal fields are equal', () {
      expect(
        const AppFailure.network(message: 'timeout', statusCode: 504),
        const AppFailure.network(message: 'timeout', statusCode: 504),
      );
      expect(
        const AppFailure.network(message: 'timeout'),
        isNot(const AppFailure.network(message: 'timeout', statusCode: 504)),
      );
    });

    test('permission failure defaults to a non-permanent denial', () {
      const failure = AppFailure.permissionDenied(permission: 'microphone');
      expect(failure, isA<PermissionFailure>());
      expect((failure as PermissionFailure).permanently, isFalse);
    });

    group('fromError', () {
      test('passes an already classified failure through untouched', () {
        const original = AppFailure.validation(message: 'empty');
        expect(
          AppFailure.fromError(original, StackTrace.empty),
          same(original),
        );
      });

      test('wraps foreign errors as unexpected and keeps the trace', () {
        final error = StateError('boom');
        final trace = StackTrace.current;
        final failure = AppFailure.fromError(error, trace);
        expect(failure, isA<UnexpectedFailure>());
        final unexpected = failure as UnexpectedFailure;
        expect(unexpected.error, same(error));
        expect(unexpected.stackTrace, same(trace));
      });

      test('plugs into TaskEither.tryCatch without try/catch', () async {
        final result = await TaskEither<AppFailure, int>.tryCatch(
          () async => throw const FormatException('bad'),
          AppFailure.fromError,
        ).run();
        expect(result.isLeft(), isTrue);
        expect(
          result.getLeft().toNullable(),
          isA<UnexpectedFailure>().having(
            (f) => f.error,
            'error',
            isA<FormatException>(),
          ),
        );
      });
    });

    group('isRetryable', () {
      test('network failures are retryable', () {
        expect(const AppFailure.network(message: 'x').isRetryable, isTrue);
      });

      test('permanent permission denials are not retryable', () {
        expect(
          const AppFailure.permissionDenied(permission: 'camera').isRetryable,
          isTrue,
        );
        expect(
          const AppFailure.permissionDenied(
            permission: 'camera',
            permanently: true,
          ).isRetryable,
          isFalse,
        );
      });

      test(
        'validation, database and unexpected failures are not retryable',
        () {
          expect(
            const AppFailure.validation(message: 'x').isRetryable,
            isFalse,
          );
          expect(const AppFailure.database(message: 'x').isRetryable, isFalse);
          expect(
            const AppFailure.unexpected(error: Object()).isRetryable,
            isFalse,
          );
        },
      );
    });
  });
}
