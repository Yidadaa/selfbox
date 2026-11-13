# Welcome mascot and avatar surface

- [x] Tests: opaque themed default avatar; mascot anchored above the actual input in both themes, keyboard states and narrow screens; hidden after first message.
- [x] UI: remove timeline hero, perch the dog behind the input edge with paws visible, reserve its measured dock height, add solid avatar background.
- [x] Validation: analyzer, full suite and real-font screenshots; commit and push before rebuilding arm64 release.

593 tests passed; analyzer 0 issues; 21 brand screenshots cover light/dark, 280dp and 390dp, keyboard open/closed. Dog paws remain above the input edge; default avatar uses an opaque themed circular surface.
