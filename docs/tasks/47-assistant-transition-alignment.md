# Agent loop transition alignment

## Checklist

- [x] Test: thinking, every tool, typing, failure, and idle retain the same left edge in every transition frame across themes, locales, and phone widths.
- [x] Test: rapid interrupted transitions keep outgoing and incoming surfaces anchored without horizontal drift.
- [x] Test: persisted AI replies enter the real timeline without inheriting user-message horizontal motion; existing user send animation remains unchanged.
- [x] Implement: anchor status transitions to a stable left edge and separate AI reply geometry from the composer send entrance.
- [x] Verify: run focused tests, full analyzer/test suite, and visually inspect mid-transition renders.
- [x] Document and commit: record the root cause and animation contract.

## Validation

- Regression tests reproduced status-card x offsets of 25–91dp and AI reply x of 64.79dp instead of the timeline's 16dp anchor. All sampled frames now retain 16dp, including interrupted transitions and live thinking growth.
- Focused tests: 19 passed. Full `flutter test --no-pub`: 529 passed, with 68 colocated test files registered in the bridge.
- `dart run slang`, `dart run build_runner build`, and `flutter analyze --no-pub`: successful; analyzer reports 0 issues and generated code remains under `lib/gen/`.
- Eight real-font mid-transition screenshots reviewed: thinking → tool, tool → thinking, tool → typing, and final reply, each in light and dark mode. Reproduce with `flutter test --no-pub tool/screenshots/app_screenshots_test.dart --update-goldens --name assistant_transition` using the workspace SDK.
- Root causes and the fixed-left-anchor contract recorded in `docs/mistakes.md` and ADR-043.
