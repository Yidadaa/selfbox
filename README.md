# Selfbox

Mobile-first Flutter app on a unified Liquid Glass design system. Engineering rules live in [AGENTS.md](AGENTS.md); decisions in [docs/decisions.md](docs/decisions.md).

## Setup

The Flutter SDK is project-local in `.tools/flutter` (stable 3.47.9, see ADR-001). Generated code in `lib/gen/` is not committed, so generate it after cloning:

```bash
./.tools/flutter/bin/flutter pub get
./.tools/flutter/bin/dart run slang
./.tools/flutter/bin/dart run build_runner build
```

## Gates

```bash
./.tools/flutter/bin/flutter analyze
./.tools/flutter/bin/flutter test
```

Tests live next to the code in `lib/**/__tests__/`. After adding a test file, re-register it:

```bash
./.tools/flutter/bin/dart run tool/gen_all_tests.dart
```
