## AI Core Component for Androids.
## Executes a Program and manages execution state.
## This is the "brain" of an Android.
class_name AICoreComponent
extends Node

# Preload required classes
const ProgramScript = preload("res://scripts/core/program.gd")
const InstructionScript = preload("res://scripts/core/instruction.gd")

## The Program this AI Core is currently executing.
var program = null

## Current instruction pointer (index into program.instructions).
var instruction_pointer: int = 0

## CPU capacity of this AI Core (limits program complexity).
@export var cpu_capacity: int = 10

## Whether the AI is currently executing.
var is_executing: bool = false

## Whether execution is paused (for debugging).
var is_paused: bool = false

## Current execution state (variables, memory).
var execution_state: Dictionary = {}

## References to systems (injected).
var movement_system = null
var combat_system = null


func _ready() -> void:
	# Connect to debug events
	EventBus.debug_pause_toggled.connect(_on_debug_pause_toggled)
	EventBus.debug_step_requested.connect(_on_debug_step_requested)


## Loads a Program into this AI Core.
## Validates that the program fits within CPU capacity.
func load_program(p_program) -> bool:
	if not p_program:
		push_error("[AICoreComponent] Cannot load null program")
		return false
	
	var validation: Dictionary = p_program.validate()
	if not validation["is_valid"]:
		push_error("[AICoreComponent] Program validation failed: %s" % str(validation["errors"]))
		return false
	
	var cpu_cost: int = p_program.get_total_cpu_cost()
	if cpu_cost > cpu_capacity:
		push_error("[AICoreComponent] Program CPU cost (%d) exceeds capacity (%d)" % [cpu_cost, cpu_capacity])
		return false
	
	program = p_program
	instruction_pointer = 0
	execution_state = {
		"memory": program.memory_cells.duplicate(),
		"variables": program.variables.duplicate()
	}
	
	print("[AICoreComponent] Program '%s' loaded successfully (CPU: %d/%d)" % [
		program.program_name,
		cpu_cost,
		cpu_capacity
	])
	
	return true


## Starts program execution.
func start_execution() -> void:
	if not program:
		push_error("[AICoreComponent] No program loaded")
		return
	
	is_executing = true
	instruction_pointer = 0
	print("[AICoreComponent] Execution started")


## Stops program execution.
func stop_execution() -> void:
	is_executing = false
	print("[AICoreComponent] Execution stopped")


## Executes a single instruction (called each simulation tick).
## Returns true if execution should continue, false if program ended.
func execute_step() -> bool:
	if not is_executing or is_paused or not program:
		return false
	
	if instruction_pointer >= program.instructions.size():
		# Program ended
		stop_execution()
		return false
	
	var instruction = program.instructions[instruction_pointer]
	
	# Emit debug event
	EventBus.instruction_executed.emit(instruction_pointer, execution_state)
	
	# Execute the instruction (placeholder - will be expanded in AI Translation Service)
	_execute_instruction(instruction)
	
	# Move to next instruction (or jump if GOTO)
	instruction_pointer += 1
	
	return true


## Executes a single instruction.
## Now connects to actual simulation systems.
func _execute_instruction(instruction) -> void:
	var android = get_parent()
	if not android:
		return
	
	match instruction.type:
		"MOVE":
			_execute_move(android, instruction.parameters)
		"ATTACK":
			_execute_attack(android, instruction.parameters)
		"GOTO":
			var label: String = instruction.parameters.get("label", "")
			_jump_to_label(label)
		"CONDITION":
			_execute_condition(android, instruction.parameters)
		"READ_SENSOR":
			_execute_read_sensor(android, instruction.parameters)
		"WRITE_MEMORY":
			_execute_write_memory(instruction.parameters)
		"READ_MEMORY":
			_execute_read_memory(instruction.parameters)
		"LABEL":
			# Labels are markers, no execution needed
			pass
		_:
			print("  [AI] Unknown instruction: %s" % instruction.type)


## Jumps instruction pointer to a labeled position.
func _jump_to_label(label: String) -> void:
	for i in program.instructions.size():
		var instr = program.instructions[i]
		if instr.type == "LABEL" and instr.parameters.get("name", "") == label:
			instruction_pointer = i
			return
	
	push_error("[AICoreComponent] GOTO failed: label '%s' not found" % label)


## Callback for debug pause toggle.
func _on_debug_pause_toggled(paused: bool) -> void:
	is_paused = paused
	print("[AICoreComponent] Execution %s" % ("paused" if paused else "resumed"))


## Callback for debug step request.
func _on_debug_step_requested() -> void:
	if is_paused and is_executing:
		execute_step()


## Executes a MOVE instruction.
func _execute_move(android, params: Dictionary) -> void:
	var direction: String = params.get("direction", "forward")
	var distance: float = params.get("distance", 50.0)
	
	if movement_system:
		match direction:
			"forward":
				movement_system.move_forward(android, distance)
			_:
				print("  [AI] Unknown direction: %s" % direction)
	else:
		# Fallback: simple movement
		android.position += Vector2(distance, 0)
	
	print("  [AI] MOVE %s (%f)" % [direction, distance])


## Executes an ATTACK instruction.
func _execute_attack(android, params: Dictionary) -> void:
	if not combat_system:
		print("  [AI] ATTACK (no combat system)")
		return
	
	# Find nearest enemy
	var target = combat_system.find_nearest_enemy(android)
	if not target:
		print("  [AI] ATTACK (no target found)")
		return
	
	# Check if in range
	if combat_system.is_in_attack_range(android, target):
		combat_system.perform_attack(android, target)
		print("  [AI] ATTACK %s" % target.android_name)
	else:
		print("  [AI] ATTACK (target out of range)")


## Executes a CONDITION instruction.
func _execute_condition(android, params: Dictionary) -> void:
	var condition_type: String = params.get("condition_type", "IS_HEALTH_LOW")
	var jump_if_true: String = params.get("jump_if_true", "")
	var jump_if_false: String = params.get("jump_if_false", "")
	
	var result: bool = _evaluate_condition(condition_type, android)
	print("  [AI] CONDITION %s = %s" % [condition_type, result])
	
	var target_label: String = jump_if_true if result else jump_if_false
	if not target_label.is_empty():
		_jump_to_label(target_label)


## Evaluates a condition.
func _evaluate_condition(condition_type: String, android) -> bool:
	match condition_type:
		"IS_HEALTH_LOW":
			return android.get_health_percentage() < 0.25
		"IS_HEALTH_HIGH":
			return android.get_health_percentage() > 0.75
		"IS_ENEMY_NEAR":
			if combat_system:
				var enemy = combat_system.find_nearest_enemy(android, 200.0)
				return enemy != null
			return false
		"TRUE":
			return true
		"FALSE":
			return false
		_:
			push_warning("[AICoreComponent] Unknown condition: %s" % condition_type)
			return false


## Executes a READ_SENSOR instruction.
func _execute_read_sensor(android, params: Dictionary) -> void:
	var sensor_type: String = params.get("sensor_type", "PROXIMITY")
	var store_in: String = params.get("store_in", "temp")
	
	var value: int = 0
	match sensor_type:
		"PROXIMITY":
			if combat_system:
				var enemy = combat_system.find_nearest_enemy(android, 500.0)
				if enemy:
					value = int(android.position.distance_to(enemy.position))
	
	execution_state["variables"][store_in] = value
	print("  [AI] READ_SENSOR %s -> %s = %d" % [sensor_type, store_in, value])


## Executes a WRITE_MEMORY instruction.
func _execute_write_memory(params: Dictionary) -> void:
	var cell_index: int = params.get("cell_index", 0)
	var value_source: String = params.get("value_source", "0")
	
	# Get value from variable or parse as literal
	var value: int = 0
	if execution_state["variables"].has(value_source):
		value = execution_state["variables"][value_source]
	else:
		value = int(value_source) if value_source.is_valid_int() else 0
	
	if cell_index >= 0 and cell_index < execution_state["memory"].size():
		execution_state["memory"][cell_index] = value
		print("  [AI] WRITE_MEMORY [%d] <- %d" % [cell_index, value])


## Executes a READ_MEMORY instruction.
func _execute_read_memory(params: Dictionary) -> void:
	var cell_index: int = params.get("cell_index", 0)
	var store_in: String = params.get("store_in", "temp")
	
	if cell_index >= 0 and cell_index < execution_state["memory"].size():
		var value: int = execution_state["memory"][cell_index]
		execution_state["variables"][store_in] = value
		print("  [AI] READ_MEMORY [%d] -> %s = %d" % [cell_index, store_in, value])
