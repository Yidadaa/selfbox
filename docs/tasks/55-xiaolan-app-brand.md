# 小懒应用名与渐变图标

- [x] Tests: localized app title, installed Android/iOS labels and native icon gradient direction/opacity.
- [x] Branding: rename visible app labels to 小懒; generate consistent blue-to-white icon backgrounds with safe adaptive foreground bounds.
- [x] Verify: regenerate assets/translations, review icons, full tests and analyzer; commit and push.
- [ ] Release: rebuild signed arm64-only APK and verify installed label, version, ABI and signature.

Validation: 610 tests pass; flutter analyze reports 0 issues. Generated 1024px icon reviewed; transparent runtime artwork stays separate from the launcher gradient.
