## AI Core Component for Androids.
## Executes a Program and manages execution state.
## This is the "brain" of an Android.
class_name AICoreComponent
extends Node

# Preload required classes
const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")

const MAX_INSTRUCTIONS_PER_CYCLE: int = 256

## The Program this AI Core is currently executing.
var program = null

## Current instruction pointer (index into program.instructions).
var program_counter: int = 0

## Configured CPU budget applied each frame (min of program budget and capacity).
var cpu_budget_per_cycle: int = 0

## CPU capacity of this AI Core (limits program complexity).
@export var cpu_capacity: int = 10

## Whether the AI is currently executing.
var is_executing: bool = false

## Whether execution is paused (for debugging).
var is_paused: bool = false

## Blackboard storing persistent AI state across frames.
var blackboard: Dictionary = {}

## Remaining CPU budget for the current execution cycle.
var cpu_budget_remaining: int = 0

## Counts instructions executed in the current cycle to detect runaway loops.
var instructions_executed_this_cycle: int = 0

## Pending jump index queued by control-flow instructions.
var pending_jump_index: int = -1

## Cached label indices for fast jumps.
var label_indices: Dictionary = {}

## Whether the currently loaded program has passed validation.
var is_program_valid: bool = false

## References to systems (injected).
var movement_system = null
var combat_system = null


func _ready() -> void:
	# Connect to debug events
	EventBus.debug_pause_toggled.connect(_on_debug_pause_toggled)
	EventBus.debug_step_requested.connect(_on_debug_step_requested)


## Loads a Program into this AI Core and prepares execution state.
func load_program(p_program) -> bool:
	if not p_program:
		push_error("[AICoreComponent] Cannot load null program")
		return false

	var validation: Dictionary = p_program.validate()
	if not validation["is_valid"]:
		push_error("[AICoreComponent] Program validation failed: %s" % str(validation["errors"]))
		is_program_valid = false
		return false

	var cpu_cost: int = p_program.get_total_cpu_cost()
	if cpu_cost > cpu_capacity:
		push_error("[AICoreComponent] Program CPU cost (%d) exceeds capacity (%d)" % [cpu_cost, cpu_capacity])
		is_program_valid = false
		return false

	program = p_program
	program_counter = 0
	cpu_budget_per_cycle = max(1, min(program.cpu_budget_per_tick, cpu_capacity))
	cpu_budget_remaining = 0
	instructions_executed_this_cycle = 0
	blackboard = program.blackboard_defaults.duplicate(true)
	label_indices = _build_label_indices(program)
	pending_jump_index = -1
	is_program_valid = true

	print("[AICoreComponent] Program '%s' loaded successfully (CPU Cost: %d, Per-Cycle Budget: %d)" % [
		program.program_name,
		cpu_cost,
		cpu_budget_per_cycle
	])

	return true

## Starts program execution.
func start_execution() -> void:
	if not program:
		push_error("[AICoreComponent] No program loaded")
		return

	if not is_program_valid:
		push_error("[AICoreComponent] Cannot start execution - program invalid")
		return

	is_executing = true
	is_paused = false
	program_counter = 0
	pending_jump_index = -1
	_reset_cycle_budget()
	instructions_executed_this_cycle = 0
	blackboard = program.blackboard_defaults.duplicate(true)

	print("[AICoreComponent] Execution started")


## Stops program execution.
func stop_execution() -> void:
	is_executing = false
	is_paused = false
	cpu_budget_remaining = 0
	instructions_executed_this_cycle = 0
	pending_jump_index = -1
	print("[AICoreComponent] Execution stopped")


## Executes a single instruction (called each simulation tick).
## Returns true if execution should continue, false if program ended.
func execute_step() -> bool:
	if not is_executing or is_paused or not program:
		return false

	if program_counter >= program.instructions.size():
		# Program ended
		stop_execution()
		return false
	if cpu_budget_remaining <= 0:
		_reset_cycle_budget()
		return false

	var instruction = program.instructions[program_counter]
	if not instruction:
		push_error("[AICoreComponent] Null instruction encountered at index %d" % program_counter)
		program_counter += 1
		return false

	# Emit debug event with snapshot of blackboard
	EventBus.instruction_executed.emit(program_counter, blackboard.duplicate(true))

	_execute_instruction(instruction)

	if not is_executing:
		return false

	var instruction_cost: int = max(instruction.cpu_cost, 0)
	cpu_budget_remaining = max(0, cpu_budget_remaining - instruction_cost)
	instructions_executed_this_cycle += 1
	if instructions_executed_this_cycle > MAX_INSTRUCTIONS_PER_CYCLE:
		push_error("[AICoreComponent] Potential infinite loop detected (>%d instructions)" % MAX_INSTRUCTIONS_PER_CYCLE)
		stop_execution()
		return false

	_apply_pending_jump()
	return true


## Executes a single instruction.
func _execute_instruction(instruction) -> void:
	if not instruction:
		return

	var android = get_parent()
	if not android:
		return

	pending_jump_index = -1

	match instruction.type:
		"SET_VARIABLE":
			_handle_set_variable(instruction.parameters)
		"MATH_OP":
			_handle_math_op(instruction.parameters)
		"VECTOR_OP":
			_handle_vector_op(instruction.parameters)
		"GET_SENSOR_DATA":
			_handle_sensor_data(android, instruction.parameters)
		"DEBUG_LOG":
			_handle_debug_log(instruction.parameters)
		"LABEL":
			pass
		"JUMP_IF":
			_handle_jump_if(instruction.parameters)
		"SET_TARGET_VELOCITY":
			_handle_set_target_velocity(android, instruction.parameters)
		"SET_ROTATION_TARGET":
			_handle_set_rotation_target(android, instruction.parameters)
		"FIRE_WEAPON":
			_handle_fire_weapon(android, instruction.parameters)
		_:
			push_warning("[AICoreComponent] Unknown instruction type '%s'" % instruction.type)


## Jumps program counter to a labeled position on next tick.
func _queue_jump_to_label(label: String) -> void:
	if label_indices.has(label):
		pending_jump_index = label_indices[label]
	else:
		push_error("[AICoreComponent] JUMP failed: label '%s' not found" % label)


func _apply_pending_jump() -> void:
	if pending_jump_index >= 0:
		program_counter = pending_jump_index
		pending_jump_index = -1
	else:
		program_counter += 1


func _reset_cycle_budget() -> void:
	cpu_budget_remaining = cpu_budget_per_cycle
	instructions_executed_this_cycle = 0


func _build_label_indices(p_program) -> Dictionary:
	var indices: Dictionary = {}
	if not p_program:
		return indices
	for i in p_program.instructions.size():
		var instruction = p_program.instructions[i]
		if instruction and instruction.type == "LABEL":
			var name: String = instruction.parameters.get("name", "")
			if not name.is_empty():
				indices[name] = i
	return indices


func _handle_set_variable(params: Dictionary) -> void:
	var target: String = params.get("target", "")
	if target.is_empty():
		push_error("[AICoreComponent] SET_VARIABLE missing 'target'")
		return

	if params.has("source"):
		blackboard[target] = _resolve_value(params.get("source"))
		return
	if params.has("value"):
		blackboard[target] = _resolve_value(params.get("value"))
		return

	# Default to null if no value specified
	blackboard[target] = null


func _handle_math_op(params: Dictionary) -> void:
	var operation: String = str(params.get("operation", "add")).to_lower()
	var lhs_value = _resolve_numeric(params.get("lhs", 0))
	var rhs_value = _resolve_numeric(params.get("rhs", 0))
	var store_in: String = params.get("store_in", "")

	if store_in.is_empty():
		push_error("[AICoreComponent] MATH_OP missing 'store_in'")
		return
	if lhs_value == null or rhs_value == null:
		push_error("[AICoreComponent] MATH_OP operands must resolve to numbers")
		return

	var result: float = 0.0
	match operation:
		"add":
			result = lhs_value + rhs_value
		"subtract":
			result = lhs_value - rhs_value
		"multiply":
			result = lhs_value * rhs_value
		"divide":
			if rhs_value == 0:
				push_error("[AICoreComponent] MATH_OP division by zero")
				return
			result = lhs_value / rhs_value
		_:
			push_error("[AICoreComponent] MATH_OP unknown operation '%s'" % operation)
			return

	blackboard[store_in] = result


func _handle_vector_op(params: Dictionary) -> void:
	var operation: String = str(params.get("operation", "add")).to_lower()
	var vector_a: Vector2 = _resolve_vector(params.get("vector_a", Vector2.ZERO))
	var vector_b: Vector2 = _resolve_vector(params.get("vector_b", Vector2.ZERO))
	var scalar: float = _resolve_numeric(params.get("scalar", 1.0)) if params.has("scalar") else 1.0
	var store_in: String = params.get("store_in", "")

	if store_in.is_empty():
		push_error("[AICoreComponent] VECTOR_OP missing 'store_in'")
		return

	var result: Vector2 = Vector2.ZERO
	match operation:
		"add":
			result = vector_a + vector_b
		"subtract":
			result = vector_a - vector_b
		"normalize":
			result = vector_a.normalized()
		"scale":
			result = vector_a * scalar
		_:
			push_error("[AICoreComponent] VECTOR_OP unknown operation '%s'" % operation)
			return

	blackboard[store_in] = result


func _handle_sensor_data(android, params: Dictionary) -> void:
	var sensor: String = str(params.get("sensor", "")).to_upper()
	var store_in: String = params.get("store_in", "")
	if store_in.is_empty():
		push_error("[AICoreComponent] GET_SENSOR_DATA missing 'store_in'")
		return

	var value = null
	match sensor:
		"SELF_POSITION":
			value = android.global_position
		"SELF_ROTATION":
			value = rad_to_deg(android.rotation)
		"TARGET_VELOCITY":
			var stored_velocity = android.get("target_velocity") if android.has_method("get") else null
			value = stored_velocity if stored_velocity is Vector2 else Vector2.ZERO
		"NEAREST_ENEMY_POSITION":
			if combat_system:
				var enemy = combat_system.find_nearest_enemy(android)
				value = enemy.global_position if enemy else Vector2.ZERO
			else:
				value = Vector2.ZERO
		"NEAREST_ENEMY_DISTANCE":
			if combat_system:
				var enemy = combat_system.find_nearest_enemy(android)
				value = android.global_position.distance_to(enemy.global_position) if enemy else -1.0
			else:
				value = -1.0
		_:
			push_warning("[AICoreComponent] GET_SENSOR_DATA unknown sensor '%s'" % sensor)
			value = null

	blackboard[store_in] = value


func _handle_debug_log(params: Dictionary) -> void:
	var message: String = str(params.get("message", ""))
	var values = params.get("values", [])
	var resolved_values: Array = []
	if values is Array:
		for entry in values:
			resolved_values.append(_resolve_value(entry))

	print("[AICoreComponent][DEBUG] %s %s" % [message, resolved_values])


func _handle_jump_if(params: Dictionary) -> void:
	var target_label: String = params.get("target_label", "")
	if target_label.is_empty():
		push_error("[AICoreComponent] JUMP_IF missing 'target_label'")
		return

	var condition_data = params.get("condition", {})
	var negate: bool = params.get("negate", false)
	var condition_met: bool = _evaluate_condition(condition_data)
	if negate:
		condition_met = not condition_met

	if condition_met:
		_queue_jump_to_label(target_label)
	else:
		var else_label: String = params.get("else_label", "")
		if not else_label.is_empty():
			_queue_jump_to_label(else_label)


func _handle_set_target_velocity(android, params: Dictionary) -> void:
	var velocity: Vector2 = _resolve_vector(params.get("velocity", Vector2.ZERO))
	var blend_value = _resolve_numeric(params.get("blend", 1.0))
	if blend_value == null:
		blend_value = 1.0
	var blend: float = clamp(blend_value, 0.0, 1.0)
	android.set("target_velocity", velocity)
	android.set("velocity_blend", blend)


func _handle_set_rotation_target(android, params: Dictionary) -> void:
	var rotation_value = _resolve_numeric(params.get("rotation_deg", 0.0))
	if rotation_value == null:
		rotation_value = 0.0
	android.set("rotation_target_deg", rotation_value)


func _handle_fire_weapon(android, params: Dictionary) -> void:
	if not combat_system:
		push_warning("[AICoreComponent] FIRE_WEAPON skipped - no combat system")
		return

	var target = combat_system.find_nearest_enemy(android)
	if not target:
		push_warning("[AICoreComponent] FIRE_WEAPON no target")
		return

	combat_system.perform_attack(android, target)
	blackboard["last_attack_target"] = target


func _resolve_value(raw):
	if typeof(raw) == TYPE_STRING:
		if blackboard.has(raw):
			return blackboard[raw]
		if raw.is_valid_float():
			return raw.to_float()
		return raw
	if typeof(raw) == TYPE_DICTIONARY:
		var dict: Dictionary = raw
		var variant_type: String = str(dict.get("type", "literal")).to_lower()
		match variant_type:
			"variable":
				return blackboard.get(dict.get("name", ""), null)
			"vector":
				return Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
			"literal":
				return dict.get("value")
	return raw


func _resolve_numeric(raw):
	var value = _resolve_value(raw)
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_BOOL:
			return 1.0 if value else 0.0
		TYPE_STRING:
			return value.to_float() if value.is_valid_float() else null
	return null


func _resolve_vector(raw) -> Vector2:
	var value = _resolve_value(raw)
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(value[0], value[1])
	if typeof(value) == TYPE_DICTIONARY:
		return Vector2(value.get("x", 0.0), value.get("y", 0.0))
	return Vector2.ZERO


func _evaluate_condition(condition_data) -> bool:
	if condition_data == null:
		return false
	if typeof(condition_data) == TYPE_BOOL:
		return condition_data
	if typeof(condition_data) != TYPE_DICTIONARY:
		return bool(_resolve_value(condition_data))

	var comparator: String = str(condition_data.get("operator", "==")).to_lower()
	if condition_data.is_empty():
		return false

	var lhs_raw = condition_data.get("lhs")
	var rhs_raw = condition_data.get("rhs")

	match comparator:
		"==", "equals":
			return _resolve_value(lhs_raw) == _resolve_value(rhs_raw)
		"!=", "not_equals":
			return _resolve_value(lhs_raw) != _resolve_value(rhs_raw)
		">", "greater_than":
			return _compare_numeric(lhs_raw, rhs_raw, func(a, b): return a > b)
		"<", "less_than":
			return _compare_numeric(lhs_raw, rhs_raw, func(a, b): return a < b)
		">=", "greater_or_equal":
			return _compare_numeric(lhs_raw, rhs_raw, func(a, b): return a >= b)
		"<=", "less_or_equal":
			return _compare_numeric(lhs_raw, rhs_raw, func(a, b): return a <= b)
		"is_true":
			return bool(_resolve_value(lhs_raw))
		"is_false":
			return not bool(_resolve_value(lhs_raw))
	return false


func _compare_numeric(lhs_raw, rhs_raw, comparator: Callable) -> bool:
	var lhs_value = _resolve_numeric(lhs_raw)
	var rhs_value = _resolve_numeric(rhs_raw)
	if lhs_value == null or rhs_value == null:
		push_warning("[AICoreComponent] Numeric comparison received non-numeric values")
		return false
	return comparator.call(lhs_value, rhs_value)


## Callback for debug pause toggle.
func _on_debug_pause_toggled(paused: bool) -> void:
	is_paused = paused


## Callback for debug step request.
func _on_debug_step_requested() -> void:
	if is_paused and is_executing:
		execute_step()
