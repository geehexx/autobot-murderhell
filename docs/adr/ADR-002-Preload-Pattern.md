# ADR-002: Preload Pattern Instead of class_name

**Status:** Accepted  
**Date:** 2025-10-05  
**Deciders:** Development Team

## Context

During early development, the project experienced critical **"Could not find type in current scope"** parse-time errors when using Godot's `class_name` keyword for custom script types. These errors affected:
- `Program`
- `Instruction`
- `AndroidEntity`
- `HealthComponent`
- `AICoreComponent`
- `MovementSystem`
- `CombatSystem`

The errors occurred at parse time, before runtime, making them difficult to debug. The Godot 4.3+ parser was unable to resolve `class_name` types in certain contexts, particularly when:
- Scripts referenced each other circularly
- Type annotations were used in function signatures
- Scripts were loaded across different autoload boundaries

Three approaches were evaluated:
1. **Continue with class_name** - Keep trying to fix the parse errors
2. **Hybrid approach** - Use `class_name` where it works, `preload` elsewhere
3. **Preload pattern exclusively** - Replace all `class_name` with `preload()` for custom types

## Decision

We will **exclusively use the `preload()` pattern for all custom script references** and **never use `class_name` in this project**.

### Required Pattern

```gdscript
# ✅ CORRECT - Preload pattern
const ProgramScript = preload("res://scripts/core/program.gd")
const InstructionScript = preload("res://scripts/core/instruction.gd")

var my_program = ProgramScript.new()

func process_program(program):  # No type annotation
    if program.has_method("validate"):
        return program.validate()
```

### Forbidden Patterns

```gdscript
# ❌ WRONG - Never use class_name
class_name Program
class_name MyCustomClass

# ❌ WRONG - Never use class_name type annotations
var program: Program = Program.new()
func my_function(param: Program) -> bool:
    pass

# ❌ WRONG - Never use 'is' with class_name types
if node is Program:
    pass
```

### Type Checking Approach

Use **duck typing** instead of `is ClassName`:

```gdscript
# ✅ CORRECT - Duck typing
if node.has_method("load_program"):
    node.load_program(my_program)

if "android_name" in node:
    print(node.android_name)
```

### Instance Duplication

For classes that need duplication, use `get_script().new()`:

```gdscript
func duplicate_program():
    var copy = get_script().new(program_name, max_memory_cells)
    # Copy properties...
    return copy
```

## Consequences

### Positive

- **Eliminates parse-time errors**: All "Could not find type in current scope" errors are resolved
- **Predictable behavior**: `preload()` is more explicit and easier to reason about
- **Works across all contexts**: No special cases or exceptions needed
- **Simpler mental model**: One pattern for all custom script references
- **Better for Godot's architecture**: Aligns with Godot's scene-centric design philosophy

### Negative

- **More verbose**: Requires `const X = preload(...)` at the top of files
- **No IDE autocomplete for types**: Lose some autocomplete benefits from typed annotations
- **Breaks GDScript convention**: The official style guide recommends using `class_name`
- **Type checking limitations**: Cannot use `is ClassName`, must use duck typing
- **Less type safety**: No compile-time type checking for custom classes

### Neutral

- **Built-in types still use static typing**: `var health: int = 100` is still encouraged
- **Duck typing is idiomatic**: Common in dynamic languages, just requires discipline
- **Test suite unaffected**: GdUnit4 tests work identically with both approaches
- **Performance**: No meaningful performance difference between patterns

## Implementation Notes

### For New Scripts

When creating a new script:

1. **Do not add `class_name`**
2. **Use `preload()` for dependencies** at the top of the file:
   ```gdscript
   const DependencyScript = preload("res://scripts/path/to/dependency.gd")
   ```
3. **Avoid type annotations** for custom script parameters
4. **Use duck typing** for type checks

### For Existing Scripts

All existing scripts have been refactored to follow this pattern. Do not reintroduce `class_name` under any circumstances.

### For Type Safety

While we lose compile-time type checking for custom classes, we compensate with:
- **Comprehensive test suite**: GdUnit4 tests verify correct types at runtime
- **Duck typing checks**: Use `has_method()` and `in` operator before calling methods
- **Documentation**: Clear docstrings explain expected types
- **Code review**: PRs verify correct patterns during review

### Static Typing Guidelines

Use static typing for:
- ✅ Built-in types (`int`, `float`, `String`, `Vector2`, etc.)
- ✅ `@export` variables for editor integration
- ✅ Return types when returning built-in types

Do not use static typing for:
- ❌ Custom script types (use duck typing instead)
- ❌ Parameters that accept custom scripts

## References

- `TESTING_RESULTS.md` - Documents the original parse errors and the solution
- `CONTRIBUTING.md` - Code style guide with preload pattern examples
- [Godot Issue #43438](https://github.com/godotengine/godot/issues/43438) - Related GDScript parser issues
- Test files in `tests/` - Demonstrate correct usage patterns
