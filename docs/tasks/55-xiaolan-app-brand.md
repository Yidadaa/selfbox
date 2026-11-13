# 小懒应用名与渐变图标

- [x] Tests: localized app title, installed Android/iOS labels and native icon gradient direction/opacity.
- [x] Branding: rename visible app labels to 小懒; generate consistent blue-to-white icon backgrounds with safe adaptive foreground bounds.
- [x] Verify: regenerate assets/translations, review icons, full tests and analyzer; commit and push.
- [x] Release: rebuild signed arm64-only APK and verify installed label, version, ABI and signature.

Validation: 610 tests pass; flutter analyze reports 0 issues. Generated 1024px icon reviewed; transparent runtime artwork stays separate from the launcher gradient.

Release: build/app/outputs/flutter-apk/xiaolan-0.3.0-arm64-v8a-release.apk (source 961420d). Verified application label 小懒, versionName 0.3.0, split versionCode 2003, arm64-v8a only, valid v2 release signature matching prior packages, and packaged gradient pixels. SHA-256: C69FAF87B48B13EBAFC6336F4C91DC51D8F9C5BD2EF45E92AC85A732A9535077.
