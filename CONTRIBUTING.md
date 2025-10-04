# Contributing to Autobot Murderhell

## Development Workflow

This project follows **GitFlow** branching model and **Test-Driven Development (TDD)** principles.

### Branching Model (GitFlow)

- `master`: Production-ready code, tagged with version numbers
- `develop`: Main development branch, integration point for features
- `feature/*`: Feature branches, created from `develop`
- `hotfix/*`: Emergency fixes, created from `master`
- `release/*`: Release preparation branches

### Creating a Feature Branch

```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/my-feature-name

# Work on your feature...
# When done, merge back to develop
git checkout develop
git merge --no-ff feature/my-feature-name
```

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

We strictly follow the [Official GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html).

### Key Rules

- **Classes/Nodes**: `PascalCase` (e.g., `AndroidEntity`, `BlockEditor`)
- **Functions/Variables**: `snake_case` (e.g., `get_cpu_cost()`, `total_damage`)
- **Constants**: `CONSTANT_CASE` (e.g., `MAX_HEALTH`, `DEFAULT_CPU_COST`)
- **Private members**: Prefix with `_` (e.g., `_internal_state`, `_calculate_damage()`)
- **Static Typing**: Always use static typing

```gdscript
# Good
var health: int = 100
func calculate_damage(base: float, multiplier: float) -> float:
    return base * multiplier

# Bad
var health = 100  # No type
func calculate_damage(base, multiplier):  # No types
    return base * multiplier
```

### Documentation

Use doc comments for all public classes, functions, and exports:

```gdscript
## Represents an Android entity in the simulation.
## This is the aggregate root for combat and movement operations.
class_name AndroidEntity
extends Node2D

## The current health of this Android.
@export var health: int = 100

## Deals damage to this Android, accounting for armor.
## Returns the actual damage dealt after mitigation.
func take_damage(damage: float) -> float:
    # Implementation...
    pass
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

## Before Submitting a Pull Request

1. ✅ All tests pass
2. ✅ New code has corresponding tests
3. ✅ Code follows GDScript style guide
4. ✅ Commit messages follow Conventional Commits format
5. ✅ No debug print statements left in code
6. ✅ Documentation updated if needed

## Questions?

Refer to the **Project Charter** document for architectural decisions and design philosophy.
