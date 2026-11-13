# Agent identity and avatar presets

- [x] Tests: retain legacy user nickname/avatar, persist separate Agent identity, validate names and avatar references, retain user-only memory naming.
- [x] Tests: both header entry points, localized default names, Agent/user field independence, preset selection/cancellation, explicit gallery flow, failure and narrow layouts.
- [x] Data: additive ObjectBox fields with stable existing IDs; separate Agent identity in model and prompt.
- [x] UI: Agent profile form, localized 小懒 / Dozy, themed dog presets and final round gallery entry.
- [x] Validate: codegen, full tests, analyzer and light/dark screenshots; update documentation and commit.

Validation: 608 tests passed; 8 real-font screenshots cover Chinese/English, light/dark and 280dp enlarged text. Existing ObjectBox entity/property UIDs preserved; only agentName and agentAvatar appended. Gallery selection, cancellation, denial and save retry covered. Avatar presets remain drafts until save; Agent and user identities are independently passed to the model.
