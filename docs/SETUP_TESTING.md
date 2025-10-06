# Testing Setup Guide

## Prerequisites

- **Godot 4.5+** installed and accessible via command line (`/snap/bin/godot4` validated)
- **GdUnit4** plugin (bundled as git submodule under `addons/gdUnit4/`)
- **tools/run_godot_checks.sh** executable (for headless smoke + lint wrapper)

## Installing GdUnit4

### Method 1: Via Godot Asset Library (Recommended)

1. Open the project in Godot
2. Go to `AssetLib` tab at the top
3. Search for "GdUnit4"
4. Click "Download" → "Install"
5. Enable the plugin in `Project → Project Settings → Plugins`

### Method 2: Manual Installation

1. Download GdUnit4 from [GitHub](https://github.com/MikeSchulze/gdUnit4)
2. Extract to `addons/gdUnit4/` in the project root
3. Enable the plugin in `Project → Project Settings → Plugins`

### Method 3: Git Submodule (For CI/CD)

```bash
git submodule add https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
git submodule update --init --recursive
```

### Preventing `--check-only` hangs

Godot will **hang indefinitely** if the startup scene never calls `SceneTree.quit()` while running in `--check-only` mode. We fixed this by adding `_maybe_quit_for_headless_check()` in `src/core/game_controller.gd`, which detects the CLI flag and defers a quit. If you add new entry points, make sure they also honor `--check-only`.

To guarantee the check exits during CI, use `tools/run_godot_checks.sh` (added in this repo) or wrap the command with `timeout` locally:

```bash
GDT=$(command -v godot4 || command -v /snap/bin/godot4)
timeout 40s "$GDT" --headless --path . --check-only
```

If the command times out, inspect startup scripts for missing quit handlers.

## Running Tests

### Via Godot Editor

1. Open project in Godot
2. Go to `Project → Tools → GdUnit4`
3. Select `Run All Tests` or choose specific suites (core/program, services/ai_translation_service, progression/player_profile)

### Via Command Line

```bash
# Execute core regression matrix (ADR-003 compliant suites)
/snap/bin/godot4 --headless --path . \
  --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --add tests/core/test_program.gd \
  --add tests/services/test_ai_translation_service.gd \
  --add tests/progression/test_player_profile.gd \
  --ignoreHeadlessMode

# Smoke test (headless)
/snap/bin/godot4 --headless --path . --script smoke_test.gd --quit-timeout 5

# Headless integrity + lint helper
tools/run_godot_checks.sh
```

## Current Test Status

### ✅ ADR-003 Regression Suites

- `tests/core/test_program.gd` — validates ADR-003 instruction definitions, label mapping, and CPU budgeting.
- `tests/services/test_ai_translation_service.gd` — confirms EventBus override pipeline emits `translation_completed` signal.
- `tests/progression/test_player_profile.gd` — verifies progression persistence stores ADR-003 unlock metadata.

### ✅ Smoke Coverage

- `smoke_test.gd` — headless sanity check for instruction registration, translation service wiring, and startup logging.
- `tools/run_godot_checks.sh` — wraps `--check-only`, GdUnit, and lint invocations for CI parity.

### 🚧 Pending Expansion (Unit 4)

- `tests/ui/test_tutorial_system.gd` — placeholder suite to be populated during Phase 2 tooling.
- `tests/simulation/test_ai_core_component.gd` — forthcoming coverage for instruction execution loop.

## Test Coverage Goals

| Component | Target Coverage | Current Status |
|-----------|----------------|----------------|
| Core Logic (Program, Instruction) | 100% | ✅ ADR-003 regression suites passing |
| Services | 95% | ✅ AI Translation + Persistence validated |
| Simulation Systems | 80% | ⚠️ Awaiting AI core component suite (Unit 4) |
| UI Components | 60% | ⚠️ Tutorial/system automation pending |

## Writing New Tests

Follow TDD (Test-Driven Development):

1. **RED** - Write a failing test
2. **GREEN** - Write minimal code to pass
3. **REFACTOR** - Improve code quality

### Example Test

```gdscript
## Test suite for MyFeature
extends GdUnitTestSuite

const MyFeatureScript = preload("res://src/my_feature.gd")

func before_test() -> void:
    # Setup before each test
    pass

func after_test() -> void:
    # Cleanup after each test
    pass

func test_my_feature_does_something() -> void:
    # Arrange
    var feature = MyFeatureScript.new()
    
    # Act
    var result = feature.do_something(5)
    
    # Assert
    assert_int(result).is_equal(10)
```

## CI/CD Integration

GitHub Actions automatically runs tests on:
- Every push to `develop`
- Every pull request to `develop`
- Every push to `release/*` branches

See `.github/workflows/godot-ci.yml` for configuration.

## Troubleshooting

### "GdUnit4 not found" Error

- Ensure the plugin resides in `addons/gdUnit4/` (git submodule or manual copy).
- Confirm the plugin is enabled in Project Settings → Plugins.

### "Could not find type in current scope" Error

- You're using `class_name` instead of preload pattern.
- See `docs/adr/ADR-002-Preload-Pattern.md` for required approach.

### Tests Pass Locally but Fail in CI

- Confirm commands use `/snap/bin/godot4` or alias on CI runners.
- Verify EventBus autoload is available before running service suites.
- Ensure `tools/run_godot_checks.sh` exits cleanly (no hanging startup scenes).

## Next Steps

1. **Install GdUnit4** plugin (if not already synced)
2. **Run ADR-003 regression matrix** to confirm baseline
3. **Execute smoke test** prior to gameplay QA sessions
4. **Populate Unit 4 stub suites** as tooling foundation lands

## References

- [GdUnit4 Documentation](https://mikeschulze.github.io/gdUnit4/)
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
- `docs/adr/ADR-002-Preload-Pattern.md` - Why we use preload pattern
- `CONTRIBUTING.md` - Development workflow and TDD guidelines
