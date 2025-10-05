# Quick Reference Guide

## 🚀 Common Development Tasks

### Running Tests

```bash
# Run all tests
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue

# Run specific test suite
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/core/test_program.gd

# Run tests in Godot Editor
# Project → Tools → GdUnit4 → Run All Tests
```

### Creating a New Feature (TDD Workflow)

1. **Create branch from develop**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-new-feature
   ```

2. **Write failing test first (RED)**
   ```gdscript
   # tests/core/test_my_feature.gd
   extends GdUnitTestSuite
   
   func test_my_feature_does_something() -> void:
       var obj: MyClass = MyClass.new()
       var result: int = obj.do_something()
       assert_int(result).is_equal(42)
   ```

3. **Run test (should FAIL)**
   ```bash
   godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/core/test_my_feature.gd
   ```

4. **Write minimal implementation (GREEN)**
   ```gdscript
   # src/core/my_class.gd
   extends RefCounted
   
   func do_something() -> int:
       return 42
   ```

5. **Run test (should PASS)**

6. **Refactor if needed**

7. **Commit with Conventional Commits**
   ```bash
   git add tests/core/test_my_feature.gd scripts/core/my_class.gd
   git commit -m "feat(core): add MyClass with do_something method

   - Implements core functionality for X
   - Includes full test coverage
   - Follows TDD red-green-refactor cycle"
   ```

### EventBus Signal Reference

```gdscript
# Programming Context
EventBus.program_edited.emit(program)
EventBus.program_validation_requested.emit(program)
EventBus.translate_program_requested.emit(program)

# Simulation Context
EventBus.run_started.emit(level_id, program)
EventBus.run_ended.emit(result_dict)
EventBus.instruction_executed.emit(index, state_dict)
EventBus.android_damaged.emit(android, damage, source)
EventBus.android_destroyed.emit(android)

# Progression Context
EventBus.upgrade_purchased.emit(item_id)
EventBus.capability_unlocked.emit(type, id)
EventBus.resources_changed.emit(resource_type, amount)

# Debug Context
EventBus.debug_pause_toggled.emit(is_paused)
EventBus.debug_step_requested.emit()

# Persistence
EventBus.save_requested.emit()
EventBus.load_requested.emit()
```

### Creating a New Instruction Type

1. **Add to Instruction type enum (conceptually)**
   ```gdscript
   # In your instruction creation logic
   var instruction: Instruction = Instruction.new("MY_INSTRUCTION", 2, {
       "param1": "value"
   })
   ```

2. **Add translation in AITranslationService**
   ```gdscript
   # src/services/ai_translation_service.gd
   match instruction.type:
       "MY_INSTRUCTION":
           translated["execute"] = _create_my_instruction_executor(instruction.parameters)
   ```

3. **Create executor function**
   ```gdscript
   func _create_my_instruction_executor(params: Dictionary) -> Callable:
       return func(android: AndroidEntity, state: Dictionary) -> Dictionary:
           # Implementation here
           print("Executing MY_INSTRUCTION")
           return {"continue": true, "jump_to": -1}
   ```

4. **Add to Block Editor palette**
   ```gdscript
   # src/ui/block_editor.gd
   const InstructionScript = preload("res://src/core/instruction.gd")

   func _create_instruction_from_type(block_type: String):
       match block_type:
           "MY_INSTRUCTION":
               return InstructionScript.new("MY_INSTRUCTION", 2, {"param1": "default"})
   ```

5. **Write tests**
   ```gdscript
   func test_translate_my_instruction() -> void:
       var program: Program = Program.new()
       program.add_instruction(Instruction.new("MY_INSTRUCTION", 2))
       
       var result: Dictionary = translation_service.translate_program(program)
       
       assert_bool(result["success"]).is_true()
   ```
## 🏗️ Architecture Patterns

### Adding a New Component to Android

```gdscript
# 1. **Create component script**
   ```gdscript
   extends Node

@export var my_property: float = 10.0

func do_something() -> void:
    print("Component does something")

# 2. **Add to AndroidEntity**
   ```gdscript
   # src/simulation/android_entity.gd
   const MyComponentScript = preload("res://src/simulation/components/my_component.gd")

   func _ready() -> void:
       var my_component = MyComponentScript.new()
       add_child(my_component)
   ```
# 3. Access in systems
func _process_android(android: AndroidEntity) -> void:
    if android.has_node("MyComponent"):
        var comp: MyComponent = android.get_node("MyComponent")
        comp.do_something()
```

### Creating a New System

```gdscript
# src/simulation/systems/my_system.gd
extends Node

func _ready() -> void:
    print("[MySystem] Initialized")

func process_entities(delta: float) -> void:
    var entities: Array[Node] = get_tree().get_nodes_in_group("my_group")
    
    for node in entities:
        if node is AndroidEntity:
            _process_entity(node, delta)

func _process_entity(entity: AndroidEntity, delta: float) -> void:
    # System logic here
    pass

# Add to SimulationManager
var my_system: MySystem = MySystem.new()
add_child(my_system)
```

### Emitting Events from Components

```gdscript
# In a component
func take_damage(damage: float) -> void:
    current_health -= damage
    
    # Emit via EventBus
    if get_parent():
        EventBus.android_damaged.emit(get_parent(), damage, null)
```

## 📝 Code Style Quick Reference

### Naming Conventions

```gdscript
# Classes/Nodes: PascalCase
class_name PlayerProfile
class_name HealthComponent

# Functions/Variables: snake_case
func calculate_damage(base_damage: float) -> float:
    var final_damage: float = base_damage * multiplier
    return final_damage

# Constants: CONSTANT_CASE
const MAX_HEALTH: int = 100
const DEFAULT_SPEED: float = 150.0

# Private members: prefix with _
var _internal_state: Dictionary = {}
func _calculate_internal() -> void:
    pass

# Signals: past tense, snake_case
signal damage_received(amount: float)
signal item_collected(item_id: String)
```

### Type Annotations (Required)

```gdscript
# Good ✅
var health: int = 100
var name: String = "Player"
var items: Array[String] = []

func get_damage(base: float, mult: float) -> float:
    return base * mult

# Bad ❌
var health = 100  # No type
var items = []  # No type

func get_damage(base, mult):  # No types
    return base * mult
```

### Documentation

```gdscript
## Brief description of the class.
## More detailed explanation if needed.
extends Node

## The player's current health points.
@export var health: int = 100

## Calculates damage after applying armor mitigation.
## Returns the actual damage dealt.
func calculate_damage(base_damage: float, armor: float) -> float:
    var mitigation: float = min(armor * 0.01, 0.75)
    return base_damage * (1.0 - mitigation)
```

## 🔍 Debugging Tips

### Print Debugging

```gdscript
# Use structured prints with system identifier
print("[SystemName] Message here")
print("[BlockEditor] Added instruction: %s" % instruction.type)

# Print with multiple values
print("[Combat] %s attacks %s for %f damage" % [attacker.name, target.name, damage])

# Debug only (removed in release builds)
if OS.is_debug_build():
    print("[Debug] Internal state: %s" % str(internal_dict))
```

### Using the Debugger

```gdscript
# Set breakpoints in code
breakpoint  # Execution will pause here when debugger attached

# Conditional breakpoints
if some_condition:
    breakpoint
```

### Checking EventBus Connections

```gdscript
func _ready() -> void:
    # Verify EventBus is available
    if EventBus:
        print("EventBus connected")
    else:
        push_error("EventBus not found!")
    
    # Connect with error checking
    var error: Error = EventBus.my_signal.connect(_on_my_signal)
    if error != OK:
        push_error("Failed to connect signal: %d" % error)
```

## 🧪 Testing Patterns

### Testing with Mocks

```gdscript
func test_with_mock() -> void:
    var mock_android: AndroidEntity = mock(AndroidEntity)
    
    # Set up mock behavior
    do_return(true).on(mock_android).is_alive()
    
    # Test your code
    var result: bool = my_system.process(mock_android)
    
    # Verify mock was called
    verify(mock_android, 1).is_alive()
```

### Testing Signals

```gdscript
func test_signal_emitted() -> void:
    var signal_emitted: bool = false
    var received_value: int = 0
    
    var handler: Callable = func(value: int) -> void:
        signal_emitted = true
        received_value = value
    
    EventBus.my_signal.connect(handler)
    
    # Trigger signal
    my_object.do_something()
    
    await await_idle_frame()
    
    assert_bool(signal_emitted).is_true()
    assert_int(received_value).is_equal(42)
    
    EventBus.my_signal.disconnect(handler)
```

### Testing Async Operations

```gdscript
func test_async_operation() -> void:
    my_object.start_async_operation()
    
    # Wait for completion
    await await_signal(my_object.operation_completed, 1000)  # 1 second timeout
    
    assert_bool(my_object.is_complete).is_true()
```

### Using SceneRunner

```gdscript
func test_scene_interaction() -> void:
    var runner: SceneRunner = SceneRunner.new("res://scenes/my_scene.tscn")
    var scene: Node = runner.scene()
    
    # Find nodes
    var button: Button = runner.find_child("MyButton")
    
    # Simulate interaction
    runner.invoke("_on_button_pressed")
    
    await runner.await_millis(100)
    
    # Assert state
    var label: Label = runner.find_child("StatusLabel")
    assert_str(label.text).is_equal("Clicked!")
```

## 📦 Common Godot Patterns

### Autoloading Singletons

```gdscript
# In project.godot
[autoload]
EventBus="*res://autoload/event_bus.gd"

# Access anywhere
EventBus.my_signal.emit(value)
```

### Node Groups

```gdscript
# Add to group (in scene or code)
add_to_group("androids")

# Query group
var all_androids: Array[Node] = get_tree().get_nodes_in_group("androids")
```

### Custom Resources

```gdscript
class_name MyResource
extends Resource

@export var value: int = 0

# Save/Load automatically with .tres files
```

## 🐛 Common Gotchas

### Array Type Safety

```gdscript
# Typed arrays are strict
var items: Array[String] = []
items.append("hello")  # OK
items.append(123)  # Error!

# Converting arrays
var untyped: Array = [1, 2, 3]
var typed: Array[int] = []
typed.assign(untyped)  # Safe conversion
```

### Signal Connections

```gdscript
# Always disconnect signals to avoid memory leaks
func _ready() -> void:
    EventBus.my_signal.connect(_on_my_signal)

func _exit_tree() -> void:
    if EventBus.my_signal.is_connected(_on_my_signal):
        EventBus.my_signal.disconnect(_on_my_signal)
```

### Resource Duplication

```gdscript
# Shallow copy
var copy1: Program = program.duplicate()

# Deep copy (duplicates nested resources)
var copy2: Program = program.duplicate(true)

# Custom deep copy (preferred for control)
var copy3: Program = program.duplicate_program()  # Our custom method
```

## 📱 Mobile-First Considerations

### Touch Targets

```gdscript
# Minimum touch target size
button.custom_minimum_size = Vector2(48, 48)
```

### Responsive Layouts

```gdscript
# Use container nodes
# MarginContainer for padding
# VBoxContainer/HBoxContainer for auto-layout
# HSplitContainer/VSplitContainer for resizable sections
```

### Testing Touch Input

```gdscript
# Enable in project settings
# Input Devices → Pointing → Emulate Touch From Mouse = true
```

## 🔗 Useful Links

- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GdUnit4 Documentation](https://github.com/MikeSchulze/gdUnit4)
- [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
