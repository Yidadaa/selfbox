# Brand assets and v0.3 release

- [x] Tests: brand artwork rendering, default avatar, welcome/search/memory/settings empty and error states, small screens and light/dark themes.
- [x] Assets: curate asset-kit artwork, add typed runtime assets and regenerate matching launcher icons.
- [x] UI: use the dog identity for app branding/avatar and appropriate page illustrations while preserving inline AI error actions.
- [x] Release: bump to 0.3.0+3, regenerate code, pass analyzer/full tests and review screenshots.
- [x] Git: commit and push the completed changes to upstream/main.
- [ ] Android: build and inspect a release APK containing only arm64-v8a; record the output path and checksum.

Validation: 589 tests passed; analyzer 0 issues; 15 light/dark/narrow screenshots reviewed. Version 0.3.0+3. Native icons generated for Android, iOS, macOS and Windows; Android/iOS launch artwork follows light/dark backgrounds.

Branding and toast fix committed as c505844 and pushed to upstream/main; final avatar/composer refinement follows before the APK build.
