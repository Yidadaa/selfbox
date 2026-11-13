# Provider headers

## Checklist

- [x] Test: provider headers default to an empty map and survive JSON round trips.
- [x] Test: provider edits retain headers and catalog requests merge custom and authentication headers.
- [x] Test: provider page can add, edit, and remove headers from its bottom sheet.
- [x] Implement: persist custom headers in `ProviderConfig`.
- [x] Implement: pass custom headers to model catalog, probe, and chat SDK requests.
- [x] Implement: add a themed provider headers bottom sheet.
- [x] Verify: targeted tests, repository Flutter analyze, full Flutter test, and `git diff --check`.
