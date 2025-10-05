# Testing Setup Guide

## Prerequisites

- **Godot 4.3+** installed and accessible via command line
- **GdUnit4** plugin (must be installed manually)

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

Godot will **hang indefinitely** if the startup scene never calls `SceneTree.quit()` while running in `--check-only` mode. We fixed this by adding `_maybe_quit_for_headless_check()` in `scripts/game_controller.gd`, which detects the CLI flag and defers a quit. If you add new entry points, make sure they also honor `--check-only`.

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
3. Select `Run All Tests` or choose specific test suites

### Via Command Line

```bash
# Run all tests
godot-4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue

# Run specific test suite
godot-4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/core/test_program.gd

# Run with detailed output
godot-4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue --verbose
```

## Current Test Status

### ✅ Working Tests

The smoke test (`smoke_test.gd`) validates core functionality:
- Program creation
- Instruction validation
- Control flow (LABEL/GOTO)
- CPU cost calculation
- Program duplication

### ⚠️ Tests Requiring Updates

Test files in `tests/` directory use the old `class_name` pattern and need refactoring to use the `preload` pattern per ADR-002:

**Files to update:**
- `tests/core/test_program.gd`
- `tests/core/test_instruction.gd`
- `tests/services/test_ai_translation_service.gd`
- `tests/services/test_persistence_service.gd`
- `tests/progression/test_player_profile.gd`
- `tests/simulation/test_health_component.gd`
- `tests/integration/test_game_flow.gd`

**Required changes:**
```gdscript
# OLD (will fail)
extends GdUnitTestSuite

func test_example() -> void:
    var program: Program = Program.new()
    var instruction: Instruction = Instruction.new("MOVE", 1)

# NEW (correct pattern)
extends GdUnitTestSuite

const ProgramScript = preload("res://scripts/core/program.gd")
const InstructionScript = preload("res://scripts/core/instruction.gd")

func test_example() -> void:
    var program = ProgramScript.new()
    var instruction = InstructionScript.new("MOVE", 1)
```

## Test Coverage Goals

| Component | Target Coverage | Current Status |
|-----------|----------------|----------------|
| Core Logic (Program, Instruction) | 100% | ✅ Logic works, tests need refactoring |
| Services | 95% | ⚠️ Tests need refactoring |
| Simulation Systems | 80% | ⚠️ Partial coverage |
| UI Components | 60% | ❌ Not yet implemented |

## Writing New Tests

Follow TDD (Test-Driven Development):

1. **RED** - Write a failing test
2. **GREEN** - Write minimal code to pass
3. **REFACTOR** - Improve code quality

### Example Test

```gdscript
## Test suite for MyFeature
extends GdUnitTestSuite

const MyFeatureScript = preload("res://scripts/my_feature.gd")

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

- Ensure the plugin is installed in `addons/gdUnit4/`
- Check that the plugin is enabled in Project Settings → Plugins

### "Could not find type in current scope" Error

- You're using `class_name` instead of `preload` pattern
- See `docs/adr/ADR-002-Preload-Pattern.md` for correct usage

### Tests Pass Locally but Fail in CI

- Check that all dependencies use `preload` pattern
- Ensure no absolute paths are used
- Verify autoload singletons (EventBus) are properly configured

## Next Steps

1. **Install GdUnit4** plugin
2. **Update test files** to use preload pattern
3. **Run all tests** to establish baseline
4. **Write new tests** for upcoming features (TDD)

## References

- [GdUnit4 Documentation](https://mikeschulze.github.io/gdUnit4/)
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
- `docs/adr/ADR-002-Preload-Pattern.md` - Why we use preload pattern
- `CONTRIBUTING.md` - Development workflow and TDD guidelines
