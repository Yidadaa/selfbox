# Historical image viewer and optimized media

## Checklist

- [x] Add tests for JPEG normalization, 2048px bounds, thumbnail generation, invalid input, and paired deletion.
- [x] Add repository tests for unique historical image paths in chronological order.
- [x] Add viewer tests for the close control, historical swipe navigation, and thumbnail selection.
- [x] Implement isolate-based image compression and thumbnail sidecars in `MediaStore`.
- [x] Expose chronological image history through `MessageRepository` and use it in the viewer.
- [x] Add a lazy horizontal thumbnail strip and keep the selected thumbnail visible.
- [x] Run focused tests, code generation, analysis, the full test suite, and `git diff --check` with the bundled Flutter SDK.
