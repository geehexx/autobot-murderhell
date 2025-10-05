# Contributing to Autobot Murderhell

Welcome! We're glad you're interested in contributing to Autobot Murderhell. This guide will help you get started with our development workflow, coding standards, and best practices.

## 🚨 Critical: Read This First

**Before writing any code**, you must understand our architectural mandate:

### Preload Pattern Requirement

**This project uses `preload()` exclusively instead of `class_name` for script references.** This is a critical architectural decision documented in `docs/adr/ADR-002-Preload-Pattern.md`.

```gdscript
# ✅ CORRECT - Use preload pattern
const ProgramScript = preload("res://scripts/core/program.gd")
var my_program = ProgramScript.new()

func my_function(param):  # No type annotations
    return param

# ❌ WRONG - DO NOT use class_name
class_name MyClass  # NEVER use this
var my_program: Program = Program.new()  # NEVER use this
func my_function(param: MyClass) -> MyClass:  # NEVER use this
```

**Never use `class_name` in any new or refactored code.** This prevents critical "Could not find type in current scope" parse errors.

## Development Workflow

This project follows **GitFlow** branching model and **Test-Driven Development (TDD)** principles.

### Branching Model (GitFlow)

- `main`: Production-ready code, tagged with version numbers (merges from `release` or `hotfix` only)
- `develop`: Main development branch, integration point for all features
- `feature/*`: Feature branches, created from `develop` (e.g., `feature/tutorial-system`)
- `release/*`: Release preparation branches, created from `develop` for final testing
- `hotfix/*`: Emergency fixes, created from `main` for critical production bugs

See `docs/adr/ADR-001-GitFlow-Branching-Model.md` for the full rationale.

### Creating a Feature Branch

```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/my-feature-name

# Work on your feature...
# Commit frequently with conventional commit messages

# Push your feature branch
git push -u origin feature/my-feature-name

# Create a Pull Request on GitHub targeting 'develop'
```

### Pull Request Process

1. **Keep PRs small and focused** - Each PR should address a single feature or bug
2. **Write descriptive PR titles** - Follow conventional commit format
3. **Add a clear description** - Explain what changed and why
4. **Request at least one review** - All PRs require approval before merging
5. **Address feedback constructively** - Respond to all comments
6. **Ensure CI passes** - All tests must pass before merging

### Commit Message Format

We use **Conventional Commits** format. Every commit message must follow this structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semi colons, etc)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or modifying tests
- `build`: Build system or dependency changes
- `ci`: CI configuration changes
- `chore`: Other changes that don't modify src or test files

**Examples:**
```
feat(block-editor): add GOTO instruction block
fix(simulation): resolve android stuck on wall collision
docs(readme): update installation instructions
test(program): add validation test for empty program
refactor(event-bus): simplify signal naming convention
```

## Test-Driven Development (TDD)

**ALL** new features MUST follow the TDD Red-Green-Refactor cycle:

### 1. RED - Write a Failing Test

Before writing any implementation code, write a test that defines the expected behavior.

```gdscript
# tests/core/test_my_feature.gd
extends GdUnitTestSuite

func test_my_new_feature_does_something() -> void:
    var my_object: MyClass = MyClass.new()
    
    var result: int = my_object.do_something(5)
    
    assert_int(result).is_equal(10)
```

Run tests: They should **FAIL** (RED).

### 2. GREEN - Write Minimal Code to Pass

Write the simplest code that makes the test pass.

```gdscript
# scripts/core/my_class.gd
class_name MyClass
extends RefCounted

func do_something(value: int) -> int:
    return value * 2
```

Run tests: They should **PASS** (GREEN).

### 3. REFACTOR - Improve Code Quality

Improve the code design without changing its behavior. Run tests after each change to ensure they still pass.

## Code Style

We strictly follow the [Official GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html) with project-specific adaptations.

### Naming Conventions

- **File/Folder Names**: `snake_case` (e.g., `android_entity.gd`, `block_editor.tscn`)
- **Node Names in Scenes**: `PascalCase` (e.g., `PlayerCharacter`, `HealthBar`)
- **Functions/Variables**: `snake_case` (e.g., `get_cpu_cost()`, `total_damage`)
- **Constants**: `CONSTANT_CASE` (e.g., `MAX_HEALTH`, `DEFAULT_CPU_COST`)
- **Private members**: Prefix with `_` (e.g., `_internal_state`, `_calculate_damage()`)

### Type Annotations

**Use static typing for built-in types and @export variables only.** For custom script types, use duck typing or method checks.

```gdscript
# ✅ CORRECT - Static typing for built-in types
var health: int = 100
var position: Vector2 = Vector2.ZERO
@export var max_speed: float = 200.0

func calculate_damage(base: float, multiplier: float) -> float:
    return base * multiplier

# ✅ CORRECT - No type annotations for custom classes
const AndroidEntityScript = preload("res://scripts/simulation/android_entity.gd")

func process_android(android):  # No type annotation
    if android.has_method("take_damage"):
        android.take_damage(10)

# ❌ WRONG - Don't use class_name type annotations
func process_android(android: AndroidEntity) -> void:  # WRONG
    pass
```

### Type Checking Pattern

Use duck typing instead of `is ClassName`:

```gdscript
# ✅ CORRECT - Duck typing
if node.has_method("load_program"):
    node.load_program(my_program)

# ❌ WRONG - Don't use 'is' with class_name types
if node is AndroidEntity:  # WRONG
    node.load_program(my_program)
```

### Documentation

Use doc comments (`##`) for all public scripts, functions, and exports:

```gdscript
## Represents an Android entity in the simulation.
## This is the aggregate root for combat and movement operations.
##
## Usage:
##   var android = AndroidEntityScript.new()
##   android.load_program(my_program)
extends Node2D

## The current health of this Android.
@export var health: int = 100

## Deals damage to this Android, accounting for armor.
## Returns the actual damage dealt after mitigation.
func take_damage(damage: float) -> float:
    # Implementation...
    pass
```

### Project Organization

Organize files by feature, not by type:

```
scripts/
├── core/              # Core domain logic
│   ├── instruction.gd
│   └── program.gd
├── simulation/        # Simulation feature
│   ├── android_entity.gd
│   ├── components/
│   └── systems/
└── services/          # Cross-cutting services
    ├── ai_translation_service.gd
    └── persistence_service.gd
```

## Running Tests

### Via Godot Editor

1. Open project in Godot
2. Go to `Project → Tools → GdUnit4`
3. Select `Run All Tests`

### Via Command Line

```bash
# Run all tests
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue

# Run specific test suite
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/core/test_program.gd
```

## Project Structure

```
autobot-murderhell/
├── autoload/              # Autoload singletons
│   └── event_bus.gd      # Global event bus
├── scenes/                # Scene files (.tscn)
│   ├── ui/               # UI scenes
│   ├── entities/         # Entity scenes (Android, enemies)
│   └── levels/           # Level scenes
├── scripts/               # GDScript source files
│   ├── core/             # Programming Context (Program, Instruction)
│   ├── simulation/       # Simulation Context (systems, components)
│   ├── progression/      # Progression Context (upgrades, save/load)
│   └── services/         # Services (AI translator, persistence)
├── tests/                 # GdUnit4 test files (mirrors scripts/ structure)
│   ├── core/
│   ├── simulation/
│   └── progression/
├── assets/                # Game assets
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── addons/                # Godot plugins
    └── gdUnit4/          # Testing framework
```

## Code Review Guidelines

When reviewing PRs:

1. **Be constructive and respectful** - Focus on the code, not the author
2. **Ask questions** - "Have you considered...?" vs "You should..."
3. **Check for patterns** - Verify adherence to preload pattern and architectural standards
4. **Review scene files visually** - Pull the branch locally to inspect `.tscn` changes in the editor
5. **Test the changes** - Run the game and tests to verify functionality
6. **Approve when satisfied** - Use GitHub's approval feature

### What to Look For

- ✅ Preload pattern used correctly (no `class_name`)
- ✅ Tests written for new features
- ✅ Naming conventions followed
- ✅ Documentation updated
- ✅ No commented-out code or debug prints
- ✅ Architectural patterns respected (State Machine, Command, etc.)

## Architectural Patterns

This project uses specific design patterns to manage complexity:

### 1. State Machine for Gameplay Loop

The core **Design → Deploy → Analyze → Iterate** loop is managed by a Finite State Machine in `GameController`. When adding phases or transitions, follow this pattern.

### 2. Command Pattern for Player Actions

Player actions in the Design phase (e.g., adding blocks) should be encapsulated as command objects to enable undo/redo functionality in the future.

### 3. Event-Driven Architecture

Use `EventBus` autoload for decoupled communication between systems. Avoid direct dependencies where possible.

```gdscript
# ✅ CORRECT - Use EventBus
EventBus.simulation_completed.emit(result)

# ❌ WRONG - Direct coupling
ui_manager.on_simulation_completed(result)
```

## Setting Up Development Environment

### Prerequisites

- **Godot 4.3+** (stable)
- **GdUnit4** plugin (install from Asset Library)
- **Git** with GitFlow workflow understanding

### First-Time Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd autobot-murderhell
   ```

2. Check out the develop branch:
   ```bash
   git checkout develop
   ```

3. Open in Godot 4.3+

4. Install GdUnit4:
   - Project → Tools → Asset Library
   - Search "GdUnit4"
   - Download and Install

5. Run tests to verify setup:
   ```bash
   godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue
   ```

All tests should pass ✅

## Before Submitting a Pull Request

1. ✅ All tests pass locally
2. ✅ New code has corresponding tests (TDD)
3. ✅ Code follows preload pattern and style guide
4. ✅ Commit messages follow Conventional Commits format
5. ✅ No debug print statements left in code
6. ✅ Documentation updated if needed
7. ✅ Scene changes tested visually in the editor
8. ✅ PR description explains what changed and why

## Communication

For questions, discussions, and collaboration:

- **GitHub Issues** - Bug reports and feature requests
- **Pull Request comments** - Code-specific discussions
- **Discord/Slack** - Real-time team communication (see project channels)

## Additional Resources

- **Architecture Decisions**: See `docs/adr/` for Architectural Decision Records
- **MVP Status**: See `MVP_STATUS.md` for current development priorities
- **Testing Results**: See `TESTING_RESULTS.md` for known issues and solutions
- **Quick Reference**: See `QUICK_REFERENCE.md` for code patterns and examples

## Questions?

Refer to the **Architectural Decision Records** in `docs/adr/` for context on major technical choices.
