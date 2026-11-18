# Selfbox

Mobile-first Flutter app on a unified Liquid Glass design system. Engineering rules live in [AGENTS.md](AGENTS.md); decisions in [docs/decisions.md](docs/decisions.md).

## Setup

The Flutter SDK is project-local in `.tools/flutter` (stable 3.50.0, Dart 3.14.0). Generated code in `lib/gen/` is not committed, so generate it after cloning:

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

Tests mirror `lib/` under `test/`, with shared fixtures in `test/support/`. `flutter test` discovers test files directly and schedules them concurrently. See [the testing guide](docs/testing.md) for ownership, local regression commands, and separate visual/network checks.
