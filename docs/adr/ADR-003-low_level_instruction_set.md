# ADR-003: Low-Level Instruction Set Architecture

**Status:** Accepted  
**Date:** 2025-10-05  
**Deciders:** Development Team

## Context

The initial MVP design for Autobot Murderhell relied on high-level block commands such as `MOVE` and `ATTACK`. While this approach was simple to implement, it presented several critical limitations:

1. **Limited Player Creativity**: High-level abstractions prevented players from exploring nuanced strategies and optimizations
2. **Shallow Progression**: The upgrade path was limited to simple stat increases rather than unlocking new computational capabilities
3. **Unrealistic Physics**: Movement was handled as discrete teleportation or instant state changes rather than physics-based motion
4. **Lack of Resource Management**: No inherent gameplay mechanic to force players to optimize their code

Alternative approaches considered:
- **Visual Programming (Scratch-like)**: More accessible but doesn't align with the "code-based" core identity
- **High-Level + Extensions**: Adding more high-level commands would balloon complexity without addressing the core creativity issue
- **Hybrid Model**: Mixing high and low-level commands creates inconsistency and confusion

## Decision

We will **deprecate high-level commands** in favor of a **granular, low-level instruction set** inspired by assembly-like programming. The core mechanics will be:

1. **Low-Level Instructions**: Operations like `SET_VARIABLE`, `MATH_OP`, `VECTOR_OP`, `GET_SENSOR_DATA`, `JUMP_IF`, etc.
2. **Physics-Based Movement**: Transition from discrete movement to a `target_velocity` model using Godot's physics engine
3. **CPU Cycle Budget**: Each instruction has a `cpu_cost`, and the AI operates within a per-frame budget
4. **Progressive Unlocking**: Players start with basic instructions and unlock advanced ones through gameplay progression
5. **Blackboard Architecture**: Variables stored in a persistent dictionary (blackboard) accessible across execution cycles

### Instruction Set Categories

**Data & I/O** (0-1 CPU cost):
- `SET_VARIABLE`: Store literals or variable values
- `MATH_OP`: Arithmetic operations (Add, Subtract, Multiply, Divide)
- `VECTOR_OP`: Vector math (Add, Subtract, Normalize, Scale)
- `GET_SENSOR_DATA`: Read world state (position, velocity, enemy location)
- `DEBUG_LOG`: Print to console for debugging

**Control Flow** (0-1 CPU cost):
- `LABEL`: Jump target marker
- `JUMP_IF`: Conditional program counter modification

**Hardware Commands** (2 CPU cost):
- `SET_TARGET_VELOCITY`: Set desired physics velocity
- `SET_ROTATION_TARGET`: Set desired rotation in degrees
- `FIRE_WEAPON`: Instantiate and launch projectile

## Consequences

### Positive

- **Deep Player Engagement**: Players must think algorithmically, creating emergent strategies
- **Rich Progression System**: Unlocking new instructions opens genuinely new capabilities
- **Resource Optimization Gameplay**: CPU budget forces elegant, efficient solutions
- **Realistic Physics**: CharacterBody2D with velocity interpolation creates natural movement
- **Educational Value**: Players learn fundamental programming concepts (variables, loops, conditionals)
- **Infinite Replayability**: Low-level building blocks enable countless solution approaches

### Negative

- **Steep Learning Curve**: Players must understand programming fundamentals, limiting accessibility
- **Major Refactor Required**: Complete overhaul of `AICoreComponent`, `MovementSystem`, `BlockEditor`, and all tests
- **Tutorial Complexity**: Must teach low-level concepts progressively without overwhelming new players
- **Increased Testing Surface**: More instructions = more edge cases and failure modes
- **Performance Considerations**: Must implement safeguards (infinite loop detection, CPU budgets) to prevent runaway execution

### Neutral

- **Blackboard Persistence**: Variables survive across frames, requiring careful state management
- **Pre-Flight Linting**: Programs must be validated before execution (e.g., JUMP_IF targets exist)
- **Error Handling**: Division by zero, invalid jumps, and other runtime errors must fail gracefully
- **UI Flexibility**: Generic instruction panel system can adapt to any instruction without new scenes

## Implementation Notes

### AICoreComponent Structure

```gdscript
# Core state
var blackboard: Dictionary = {}
var program_counter: int = 0
var cpu_budget_remaining: int = 100
var instructions_executed_this_run: int = 0

# Execution cycle
func execute_program(delta: float) -> void:
    # Pre-flight linting
    if not _validate_program():
        return
    
    # Execute instructions until budget exhausted or halt
    while cpu_budget_remaining > 0 and program_counter < program.size():
        var instruction = program[program_counter]
        
        # Safety: Infinite loop detection
        if instructions_executed_this_run > 1000:
            push_error("Potential infinite loop detected")
            return
        
        # Check CPU cost
        if instruction.cpu_cost > cpu_budget_remaining:
            return  # Halt for this frame
        
        # Execute and advance
        _execute_instruction(instruction)
        cpu_budget_remaining -= instruction.cpu_cost
        instructions_executed_this_run += 1
        program_counter += 1
```

### Physics-Based Movement

```gdscript
# In MovementSystem._physics_process(delta)
for android in androids:
    # Smoothly interpolate to target velocity
    android.velocity = android.velocity.lerp(android.target_velocity, lerp_factor * delta)
    android.move_and_slide()
    
    # Smoothly rotate towards target
    var target_rad = deg_to_rad(android.rotation_target_deg)
    android.rotation = lerp_angle(android.rotation, target_rad, rotation_speed * delta)
```

### Progressive Unlocking

Initial tutorial unlocks: `GET_SENSOR_DATA`, `DEBUG_LOG`, `SET_ROTATION_TARGET`, `FIRE_WEAPON`

Upgrade tree unlocks: `SET_VARIABLE`, `MATH_OP`, `VECTOR_OP`, `SET_TARGET_VELOCITY`, `LABEL`, `JUMP_IF`

### Error Handling Patterns

- **Division by Zero**: Halt execution with error message
- **Invalid JUMP_IF Target**: Pre-flight linting catches before execution
- **No Enemy Found**: `GET_SENSOR_DATA` returns `Vector2.ZERO` instead of null
- **Normalize Zero Vector**: Return `Vector2.ZERO` instead of crashing

### Testing Requirements

New test suite at `tests/core/test_ai_core_component.gd` must cover:
- Blackboard variable storage and retrieval
- All instruction types execute correctly
- CPU budget enforcement
- Infinite loop detection
- Pre-flight linting (invalid jumps caught)
- Graceful error handling (division by zero, etc.)
- Control flow (LABEL, JUMP_IF)

## References

- `CONTRIBUTING.md` - Project coding standards
- [Autobot Murderhell MVP Status](../MVP_STATUS.md)
- [Assembly Language Concepts](https://en.wikipedia.org/wiki/Assembly_language)
- [Blackboard Pattern in Game AI](https://en.wikipedia.org/wiki/Blackboard_(design_pattern))
