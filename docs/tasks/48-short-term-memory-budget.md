# Short-term memory context budget

## Checklist

- [x] Tests: percentage defaults/range, JSON round-trip and legacy history-count migration, context-derived token budgets.
- [x] Tests: approximate token costs, newest-first filling at exact/over budget boundaries, multi-page history, missing/oversized question, repository failures and chronological role formatting.
- [x] Tests: 10–60% slider above live token estimate, 128k × 20% = 25,600, save/cancel/failure, no model, changed model context, narrow screens and both themes/locales.
- [x] Implement: replace history-turn count with a persisted percentage and shared budget calculation.
- [x] Implement: load recent history in bounded pages and stop at the estimated token budget; reserve system/output space and always preserve the current question.
- [x] Implement: localized short-term-memory sheet with slider, percentage and live token estimate.
- [x] Tests and UI: show a large bare token number; place equal-width Cancel and Save columns at the bottom, including narrow screens and large text.
- [x] Verify: regenerate code/test bridge, run focused/full tests and analyzer, inspect real-font sheet screenshots.
- [x] Document and commit: record migration, token estimate and history-selection contract.

## Validation

- Full suite: 553 tests passed; `flutter analyze --no-pub`: 0 issues.
- Four real-font screenshots reviewed: light/dark at 390dp, and light/dark at 280dp with 1.5× text scaling.
- Slang/build_runner output remains in `lib/gen/`; test bridge covers 75 colocated test files.
