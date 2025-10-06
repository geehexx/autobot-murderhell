# Testing Results - autobot-murderhell

## Report Date

2025-10-07

## Summary

**Status:** ✅ ADR-003 regression suites passing.

Targeted GdUnit4 suites confirm the ADR-003 instruction mapping, EventBus dependency injection override, and progression persistence flows. Smoke coverage is green under the new feature-based directory structure introduced by `ADR-004`.

## Environment

- **Engine:** Godot Engine v4.5.stable.mono.official
- **OS:** Linux (headless execution via `/snap/bin/godot4`)
- **Test Harness:** GdUnit4 4.3.0 (git submodule)
- **Project Layout:** Feature-based `src/` structure per `docs/adr/ADR-004-feature-based-structure.md`

## Regression Matrix

| Suite | Command | Result | Notes |
| --- | --- | --- | --- |
| `tests/core/test_program.gd` | `/snap/bin/godot4 --headless --path . --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/core/test_program.gd --ignoreHeadlessMode` | ✅ Pass | Validates ADR-003 instruction catalog CRUD and CPU budgeting. |
| `tests/services/test_ai_translation_service.gd` | `/snap/bin/godot4 --headless --path . --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/services/test_ai_translation_service.gd --ignoreHeadlessMode` | ✅ Pass | Confirms EventBus overrides emit `translation_completed` after ADR-003 visitor rewrite. |
| `tests/progression/test_player_profile.gd` | `/snap/bin/godot4 --headless --path . --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/progression/test_player_profile.gd --ignoreHeadlessMode` | ✅ Pass | Ensures profile persistence consumes ADR-003 instruction metadata. |
| `smoke_test.gd` | `/snap/bin/godot4 --headless --path . --script smoke_test.gd --quit-timeout 5` | ✅ Pass | Verifies boot flow, translation stubs, and ADR-003 instruction CPU math. |

## Smoke Snapshot

```text
========== SMOKE TEST START ==========
[TEST] ADR-003 instruction registration ... ✓
[TEST] Program validation (LABEL/JUMP_IF) ... ✓
[TEST] Translation service (EventBus override) ... ✓
[TEST] Player profile load/save ... ✓
========================================
✓ ALL TESTS PASSED
========================================
```

## Changes Since Previous Report

- **ADR-003 Alignment:** Removed legacy MOVE/ATTACK/GOTO opcodes; all fixtures now rely on low-level instruction set (`docs/adr/ADR-003-low_level_instruction_set.md`).
- **EventBus Diagnostics:** Permanent logging in `src/services/ai_translation_service.gd` confirms dependency injection path used during tests.
- **Feature-Based Structure:** Documentation, smoke, and CLI helpers reference the new `src/` layout described in `docs/adr/ADR-004-feature-based-structure.md`.
- **Progression Sync:** Player profile serialization updated to store ADR-003 instruction unlocks.

## Known Issues

- **UI Interaction Coverage:** Manual verification only; no automated UI regression yet (`tests/ui/test_game_flow.gd` remains smoke-level).
- **Simulation Loop Tests:** Phase 2 placeholders pending (`tests/simulation/test_ai_core_component.gd` to arrive with Unit 4).
- **CI Timeout Safeguards:** Headless checks still rely on external `timeout` when run outside `tools/run_godot_checks.sh`.

## Running the Suites

### Install Prerequisites

- Enable GdUnit4 plugin (`addons/gdUnit4/`) via Godot editor or Git submodule sync.
- Ensure `/snap/bin/godot4` (or `godot4`) is available on PATH.

### Execute Targeted Suites

```bash
/snap/bin/godot4 --headless --path . \
  --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --add tests/core/test_program.gd \
  --add tests/services/test_ai_translation_service.gd \
  --add tests/progression/test_player_profile.gd \
  --ignoreHeadlessMode
```

### Run Full Smoke

```bash
/snap/bin/godot4 --headless --path . --script smoke_test.gd --quit-timeout 5
```

### Headless Integrity Check

```bash
tools/run_godot_checks.sh
```

## Forward Look

- **Unit 3 Follow-Through:** Finalize documentation updates (`docs/SETUP_TESTING.md`, recovery plan progress).
- **Unit 4 Prep:** Add gdtoolkit formatting/linting config and stub suites for tutorial UI + AI core simulation.
- **CI Enhancements:** Fold regression matrix into `.github/workflows/godot-ci.yml` once tooling foundation lands.

## References

- `docs/adr/ADR-002-Preload-Pattern.md` — enforced by regression suites.
- `docs/adr/ADR-003-low_level_instruction_set.md` — authoritative instruction definitions.
- `docs/adr/ADR-004-feature-based-structure.md` — directory conventions referenced by smoke output.
- `docs/AITranslationService_EventBus_Recovery_Plan.md` — unit-by-unit execution checklist.
