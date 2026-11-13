# Chat glass performance

## Checklist

- [x] Test: the chat branch renders one `GlassScaffold` instead of a Shell and page pair.
- [x] Test: fixed chat chrome keeps the profile surface and attachment button standard while using premium glass for the header buttons and AI toggle.
- [x] Implement: remove the outer Shell `GlassScaffold` while retaining the shared canvas and dock layout.
- [x] Implement: keep the low-cost profile and attachment surfaces standard, with premium glass reserved for the two header buttons and AI toggle.
- [x] Verify: targeted widget tests, `flutter analyze`, full `flutter test`, and `git diff --check` with the repository Flutter SDK.
