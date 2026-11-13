# Header, dialog, and AI chrome visual polish

## Checklist

- [x] Test: standard page title capsules keep intrinsic width and a fixed 48dp height.
- [x] Test: shared action buttons and icon buttons have borderless tonal fills, including destructive semantics.
- [x] Test: pastel light stays inside input + tabs, excludes AI toggle/attachments, moves over repeated cycles, and retains coral through all 16 phases.
- [x] Test: entrance/exit reverse smoothly, reduced motion stops tickers, and extra white outlines exist only in light mode.
- [x] Test: AI/AI ready labels crossfade, slide, and resize without changing the control height or keyboard focus.
- [x] Implement: make standard page title capsules intrinsic-width with the shared toolbar height.
- [x] Implement: refine action button theme fills and remove visible outlines.
- [x] Implement: replace AI borders with a clipped animated glow behind the composer glass, preserving keyboard/focus layout.
- [x] Verify: run focused tests, full analyze/test, and render light/dark keyboard states using `.tools/flutter`.
- [x] Document: record the final UI contracts and regressions in ADR/task memory.

## Validation

- Localization regenerated; build_runner completed with generated Dart outputs inside `lib/gen`, and ObjectBox model JSON unchanged.
- `flutter analyze --no-pub`: 0 issues.
- `flutter test --no-pub`: 518 passed across 66 colocated test files and the aggregate registry check.
- Seven final screenshots rendered and visually reviewed: four composer theme/keyboard states, component library, and two confirmation dialog themes. Standard storage header also rendered and reviewed.
- `git diff --check`: clean.

## Toolchain

Use `.tools/flutter/bin/flutter.bat` (Flutter 3.47.9 / Dart 3.13.7). The global
SDK is older and must not be used for analysis, formatting, or tests.
