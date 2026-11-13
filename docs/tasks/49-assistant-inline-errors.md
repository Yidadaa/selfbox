# AI error bubble inline actions

- [x] Tests: setup/retry/dismiss actions sit inside one bubble and match normal message typography; cover light/dark, Chinese/English, narrow screens and larger text.
- [x] Implement: render recovery actions as inline text buttons with the shared message line height; preserve setup navigation, retry and dismissal.
- [x] Verify: focused/full tests, analyzer and real-font screenshots.
- [x] Document and commit the final interaction contract.

## Validation

- Full suite: 570 tests passed; analyzer: 0 issues; generated translations/code remain in `lib/gen/`.
- Reviewed 8 real-font screenshots: setup/network failures, light/dark, normal Chinese and narrow English at 1.5× text scaling.
