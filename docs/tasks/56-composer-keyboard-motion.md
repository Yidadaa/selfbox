# Composer keyboard transitions

- [x] Tests: intermediate mascot scale and Tab height/opacity, stable image decode, reversal, focus/selection preservation, narrow layouts and reduced motion.
- [x] UI: shared keyboard transition progress drives mascot sizing/anchor and Tab expansion/collapse; outgoing Tabs remain until animation completes.
- [x] Validate: targeted/full regression, analyzer, intermediate screenshots; update ADR and commit.

Validation: 615 tests passed; analyzer 0 issues. Twelve real-font screenshots cover both themes, opening/closing and 0/140/280 ms. Regression assertions verify intermediate height/opacity, stable artwork decode, preserved paw overlap, interrupted reversal, 280/390dp, focus/selection and reduced motion.
