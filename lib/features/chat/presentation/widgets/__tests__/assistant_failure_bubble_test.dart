import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/error/failure_message.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_markdown_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_live_bubbles.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/features/settings/presentation/pages/ai_providers_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

const _contentKey = ValueKey('assistant-failure-text');
const _actionKey = ValueKey('assistant-failure-action');
const _dismissKey = ValueKey('assistant-failure-dismiss');
final _question = Message(
  id: 1,
  createdAt: kTestNow,
  author: MessageAuthor.me,
  text: 'Hi',
);

class _FailedAssistant extends AssistantController {
  _FailedAssistant(this.failure);

  final AppFailure failure;
  var retries = 0;

  @override
  AssistantState build() => AssistantState.failed(failure, _question);

  @override
  Future<void> retry() async => retries++;
}

class _Fixture extends ConsumerWidget {
  const _Fixture();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.bottomLeft,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AssistantStatusBubble(
        state: ref.watch(assistantControllerProvider),
      ),
    ),
  );
}

Future<_FailedAssistant> _open(
  WidgetTester tester, {
  required AppFailure failure,
  required Brightness brightness,
  required AppLocale locale,
  double width = 1200,
  double textScale = 1,
}) async {
  final controller = _FailedAssistant(failure);
  await tester.pumpPage(
    const _Fixture(),
    brightness: brightness,
    locale: locale,
    overrides: [assistantControllerProvider.overrideWith(() => controller)],
  );
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
  return controller;
}

double _baseline(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  final baseline = box.getDryBaseline(box.constraints, TextBaseline.alphabetic);
  if (baseline == null) fail('Inline text must expose its alphabetic baseline');
  return box.localToGlobal(Offset(0, baseline)).dy;
}

void _expectInlineLayout(WidgetTester tester) {
  final content = find.byKey(_contentKey);
  final context = tester.element(content);
  final text = tester.widget<Text>(content);
  final normalStyle = AppMarkdownTheme.of(context).paragraphStyle;
  expect(text.style?.fontSize, normalStyle?.fontSize);
  expect(text.style?.height, normalStyle?.height);
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: text.style),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: TextDirection.ltr,
  )..layout();
  final lineHeight = painter.height;
  final normalBaseline = painter.computeLineMetrics().first.baseline;
  painter.dispose();
  final firstBaseline = _baseline(tester, content);
  expect(
    firstBaseline - tester.getTopLeft(content).dy,
    closeTo(normalBaseline, 0.01),
  );
  for (final key in [_actionKey, _dismissKey]) {
    final button = find.byKey(key);
    expect(find.ancestor(of: button, matching: content), findsOneWidget);
    final bounds = tester.getRect(button);
    final paragraph = tester.getRect(content);
    expect(bounds.height, closeTo(lineHeight, 0.01));
    expect(bounds.left, greaterThanOrEqualTo(paragraph.left));
    expect(bounds.right, lessThanOrEqualTo(paragraph.right + 0.5));
    expect(bounds.top, greaterThanOrEqualTo(paragraph.top));
    expect(bounds.bottom, lessThanOrEqualTo(paragraph.bottom));
    final line = (_baseline(tester, button) - firstBaseline) / lineHeight;
    expect(line, closeTo(line.round(), 0.01));
  }
  expect(
    tester.getSize(content).height / lineHeight,
    closeTo((tester.getSize(content).height / lineHeight).round(), 0.01),
  );
  expect(find.byIcon(Icons.close_rounded), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      for (final (name, failure, setup) in [
        (
          'model',
          const AppFailure.validation(message: AppFailure.noModel),
          true,
        ),
        (
          'key',
          const AppFailure.validation(message: AppFailure.missingApiKey),
          true,
        ),
        ('network', const AppFailure.network(message: 'offline'), false),
      ]) {
        testWidgets('inline $name actions match message lines in '
            '${brightness.name}/${locale.name}', (tester) async {
          await _open(
            tester,
            failure: failure,
            brightness: brightness,
            locale: locale,
          );
          _expectInlineLayout(tester);
          final content = tester.widget<Text>(find.byKey(_contentKey));
          expect(
            content.textSpan?.toPlainText(),
            contains(
              failureMessage(tester.element(find.byKey(_contentKey)), failure),
            ),
          );
          expect(
            find.text(setup ? t.assistant.setup : t.common.retry),
            findsOneWidget,
          );
          expect(find.text(t.assistant.dismiss), findsOneWidget);
          final surface = find.byType(AssistantStatusSurface);
          expect(
            find.descendant(of: surface, matching: find.byKey(_actionKey)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: surface, matching: find.byKey(_dismissKey)),
            findsOneWidget,
          );
          expect(
            tester.getRect(find.byKey(_actionKey)).top,
            tester.getRect(find.byKey(_dismissKey)).top,
          );
        });
      }

      testWidgets('inline actions wrap at 280dp and large text in '
          '${brightness.name}/${locale.name}', (tester) async {
        await _open(
          tester,
          failure: const AppFailure.network(message: 'offline'),
          brightness: brightness,
          locale: locale,
          width: 280,
          textScale: 1.5,
        );
        _expectInlineLayout(tester);
        final bounds = tester.getRect(find.byType(AssistantStatusSurface));
        expect(bounds.left, greaterThanOrEqualTo(AppSpacing.md));
        expect(bounds.right, lessThanOrEqualTo(280 - AppSpacing.md));
      });
    }
  }

  testWidgets('inline retry and dismiss retain their behaviors', (
    tester,
  ) async {
    final controller = await _open(
      tester,
      failure: const AppFailure.network(message: 'offline'),
      brightness: Brightness.dark,
      locale: AppLocale.zhCn,
    );
    await tester.tap(find.byKey(_actionKey));
    expect(controller.retries, 1);
    await tester.tap(find.byKey(_dismissKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
  });

  for (final (name, failure, setup) in [
    ('model', const AppFailure.validation(message: AppFailure.noModel), true),
    ('network', const AppFailure.network(message: 'offline'), false),
  ]) {
    testWidgets('inline $name actions work in the chat timeline', (
      tester,
    ) async {
      await tester.pumpApp(
        messages: FakeMessageRepository(seed: [_question]),
        overrides: [
          assistantControllerProvider.overrideWith(
            () => _FailedAssistant(failure),
          ),
        ],
      );
      expect(find.byKey(_contentKey), findsOneWidget);
      if (setup) {
        await tester.tap(find.byKey(_actionKey));
        await tester.pumpAndSettle();
        expect(find.byType(AiProvidersPage), findsOneWidget);
      } else {
        expect(find.text(t.common.retry), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(t.assistant.dismiss));
        await tester.pumpAndSettle();
        expect(find.byType(AssistantStatusBubble), findsNothing);
      }
    });
  }
}
