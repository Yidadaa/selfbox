import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/memory/domain/services/unified_diff.dart';

String _ok(Either<AppFailure, String> result) =>
    result.getOrElse((f) => fail('expected success, got $f'));

AppFailure _err(Either<AppFailure, String> result) =>
    result.getLeft().getOrElse(() => fail('expected a failure'));

const _profile = '''# Profile

- Name: yda
- City: Shanghai
- Job: engineer
''';

void main() {
  group('applyUnifiedDiff', () {
    test('replaces a line using a standard git-style hunk', () {
      const patch = '''--- a/user/profile.md
+++ b/user/profile.md
@@ -3,3 +3,3 @@
 - Name: yda
-- City: Shanghai
+- City: Hangzhou
 - Job: engineer
''';
      expect(_ok(applyUnifiedDiff(_profile, patch)), '''# Profile

- Name: yda
- City: Hangzhou
- Job: engineer
''');
    });

    test('accepts headers without line numbers', () {
      const patch = '''@@ @@
 - Job: engineer
+- Hobby: hiking
''';
      expect(
        _ok(applyUnifiedDiff(_profile, patch)),
        endsWith('- Job: engineer\n- Hobby: hiking\n'),
      );
    });

    test('tolerates wrong line numbers when the context is unique', () {
      const patch = '''@@ -40,2 +40,2 @@
-- Name: yda
+- Name: Yida
''';
      expect(_ok(applyUnifiedDiff(_profile, patch)), contains('- Name: Yida'));
    });

    test('applies several hunks in order', () {
      const original = 'a\nb\nc\nd\ne\nf\n';
      const patch = '''@@ -1,2 +1,2 @@
-a
+A
 b
@@ -5,2 +5,3 @@
 e
-f
+F
+g
''';
      expect(_ok(applyUnifiedDiff(original, patch)), 'A\nb\nc\nd\ne\nF\ng\n');
    });

    test('with repeated context, picks the match nearest the hint', () {
      const original = 'x\nsame\nx\nsame\n';
      const patch = '''@@ -4,1 +4,1 @@
-same
+changed
''';
      expect(_ok(applyUnifiedDiff(original, patch)), 'x\nsame\nx\nchanged\n');
    });

    test('creates content in an empty file with a pure insertion', () {
      const patch = '''@@ -0,0 +1,2 @@
+# Topic
+- first note
''';
      expect(_ok(applyUnifiedDiff('', patch)), '# Topic\n- first note\n');
    });

    test('deleting every line leaves an empty file', () {
      const patch = '''@@ -1,2 +0,0 @@
-one
-two
''';
      expect(_ok(applyUnifiedDiff('one\ntwo\n', patch)), '');
    });

    test(
      'fails when the context does not match, explaining what was expected',
      () {
        const patch = '''@@ -3,1 +3,1 @@
-- City: Beijing
+- City: Hangzhou
''';
        final failure = _err(applyUnifiedDiff(_profile, patch));
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).message,
          contains('City: Beijing'),
        );
      },
    );

    test('a later hunk cannot match lines before an earlier one', () {
      const patch = '''@@ -2,1 +2,1 @@
-b
+B
@@ -1,1 +1,1 @@
-a
+A
''';
      expect(_err(applyUnifiedDiff('a\nb\n', patch)), isA<ValidationFailure>());
    });

    test('rejects a patch without hunks', () {
      expect(
        _err(applyUnifiedDiff('a\n', 'just some text')),
        isA<ValidationFailure>(),
      );
      expect(_err(applyUnifiedDiff('a\n', '')), isA<ValidationFailure>());
    });

    test('rejects lines without a diff prefix', () {
      const patch = '''@@ @@
 a
*b
''';
      expect(_err(applyUnifiedDiff('a\nb\n', patch)), isA<ValidationFailure>());
    });

    test('keeps CRLF line endings when the file uses them', () {
      const patch = '''@@ -1,1 +1,1 @@
-a
+A
''';
      expect(_ok(applyUnifiedDiff('a\r\nb\r\n', patch)), 'A\r\nb\r\n');
    });

    test('matches against files without a trailing newline', () {
      const patch = '''@@ -2,1 +2,1 @@
-b
+B
\\ No newline at end of file
''';
      expect(_ok(applyUnifiedDiff('a\nb', patch)), 'a\nB\n');
    });

    test('treats an empty patch line as an empty context line', () {
      const original = '# T\n\nbody\n';
      const patch = '@@ -1,3 +1,3 @@\n # T\n\n-body\n+text\n';
      expect(_ok(applyUnifiedDiff(original, patch)), '# T\n\ntext\n');
    });

    test('handles CJK content', () {
      const patch = '''@@ @@
-- 喜欢：爬山
+- 喜欢：爬山、摄影
''';
      expect(
        _ok(applyUnifiedDiff('# 偏好\n- 喜欢：爬山\n', patch)),
        '# 偏好\n- 喜欢：爬山、摄影\n',
      );
    });
  });
}
