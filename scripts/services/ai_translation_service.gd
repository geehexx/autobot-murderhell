## AI Translation Service
## Translates visual block Programs into executable logic.
## Uses the Visitor pattern to decouple translation logic from block objects.
## This is the core service that bridges the Programming and Simulation contexts.
class_name AITranslationService
extends Node

# Preload required classes
const ProgramScript = preload("res://scripts/core/program.gd")
const InstructionScript = preload("res://scripts/core/instruction.gd")

## Singleton instance
static var instance: AITranslationService = null


func _init() -> void:
	if instance == null:
		instance = self


## Translates a Program into an executable script representation.
## Returns a Dictionary with execution metadata and callbacks.
func translate_program(program) -> Dictionary:
	if not program:
		push_error("[AITranslationService] Cannot translate null program")
		return _create_error_result("Null program")
	
	# Validate program first
	var validation: Dictionary = program.validate()
	if not validation["is_valid"]:
		push_error("[AITranslationService] Translation failed - invalid program: %s" % str(validation["errors"]))
		return _create_error_result(str(validation["errors"]))
	
	print("[AITranslationService] Translating program: %s" % program.program_name)
	
	# Create executable representation
	var executable: Dictionary = {
		"program_name": program.program_name,
		"instructions": [],
		"label_map": {},  # Maps label names to instruction indices
		"success": true,
		"error": ""
	}
	
	# First pass: Build label map
	for i in program.instructions.size():
		var instruction = program.instructions[i]
		if instruction.type == "LABEL":
			var label_name: String = instruction.parameters.get("name", "")
			executable["label_map"][label_name] = i
	
	# Second pass: Translate instructions
	for instruction in program.instructions:
		var translated: Dictionary = _translate_instruction(instruction, executable["label_map"])
		executable["instructions"].append(translated)
	
	print("[AITranslationService] Translation complete: %d instructions" % executable["instructions"].size())
	
	# Emit completion event
	EventBus.translation_completed.emit(executable)
	
	return executable


## Translates a single Instruction using the Visitor pattern.
## Returns a Dictionary with execution callback and metadata.
func _translate_instruction(instruction, label_map: Dictionary) -> Dictionary:
	var translated: Dictionary = {
		"type": instruction.type,
		"instruction_id": instruction.instruction_id,
		"cpu_cost": instruction.cpu_cost,
		"parameters": instruction.parameters.duplicate(true),
		"execute": func(_android, _state: Dictionary) -> Dictionary:
			return {"continue": true, "jump_to": -1}
	}
	
	# Use Visitor pattern to create type-specific execution logic
	match instruction.type:
		"MOVE":
			translated["execute"] = _create_move_executor(instruction.parameters)
		"ATTACK":
			translated["execute"] = _create_attack_executor(instruction.parameters)
		"GOTO":
			translated["execute"] = _create_goto_executor(instruction.parameters, label_map)
		"CONDITION":
			translated["execute"] = _create_condition_executor(instruction.parameters, label_map)
		"READ_SENSOR":
			translated["execute"] = _create_sensor_executor(instruction.parameters)
		"WRITE_MEMORY":
			translated["execute"] = _create_memory_write_executor(instruction.parameters)
		"READ_MEMORY":
			translated["execute"] = _create_memory_read_executor(instruction.parameters)
		"LABEL":
			# Labels are markers, no execution needed
			translated["execute"] = func(_a, _s: Dictionary) -> Dictionary:
				return {"continue": true, "jump_to": -1}
		_:
			push_warning("[AITranslationService] Unknown instruction type: %s" % instruction.type)
			translated["execute"] = _create_noop_executor()
	
	return translated


## Creates a MOVE instruction executor.
func _create_move_executor(params: Dictionary) -> Callable:
	var direction: String = params.get("direction", "forward")
	var distance: float = params.get("distance", 1.0)
	
	return func(android, _state: Dictionary) -> Dictionary:
		# Placeholder - actual movement will be handled by MovementSystem
		print("    [Execute] MOVE %s (%f units)" % [direction, distance])
		# In real implementation, this would emit a movement request
		# or directly modify the android's velocity/position
		return {"continue": true, "jump_to": -1}


## Creates an ATTACK instruction executor.
func _create_attack_executor(params: Dictionary) -> Callable:
	return func(android, _state: Dictionary) -> Dictionary:
		print("    [Execute] ATTACK")
		# Placeholder - actual combat will be handled by CombatSystem
		return {"continue": true, "jump_to": -1}


## Creates a GOTO instruction executor.
func _create_goto_executor(params: Dictionary, label_map: Dictionary) -> Callable:
	var label: String = params.get("label", "")
	var target_index: int = label_map.get(label, -1)
	
	return func(_android, _state: Dictionary) -> Dictionary:
		print("    [Execute] GOTO %s (index %d)" % [label, target_index])
		return {"continue": true, "jump_to": target_index}


## Creates a CONDITION instruction executor.
func _create_condition_executor(params: Dictionary, label_map: Dictionary) -> Callable:
	var condition_type: String = params.get("condition_type", "IS_HEALTH_LOW")
	var jump_if_true: String = params.get("jump_if_true", "")
	var jump_if_false: String = params.get("jump_if_false", "")
	
	return func(android, _state: Dictionary) -> Dictionary:
		var condition_result: bool = _evaluate_condition(condition_type, android)
		print("    [Execute] CONDITION %s = %s" % [condition_type, condition_result])
		
		var target_label: String = jump_if_true if condition_result else jump_if_false
		if target_label.is_empty():
			return {"continue": true, "jump_to": -1}
		
		var target_index: int = label_map.get(target_label, -1)
		return {"continue": true, "jump_to": target_index}


## Creates a READ_SENSOR instruction executor.
func _create_sensor_executor(params: Dictionary) -> Callable:
	var sensor_type: String = params.get("sensor_type", "PROXIMITY")
	var store_in: String = params.get("store_in", "temp")
	
	return func(_android, state: Dictionary) -> Dictionary:
		print("    [Execute] READ_SENSOR %s -> %s" % [sensor_type, store_in])
		# Placeholder - read sensor data and store in state
		state["variables"][store_in] = 0  # Dummy value
		return {"continue": true, "jump_to": -1}


## Creates a WRITE_MEMORY instruction executor.
func _create_memory_write_executor(params: Dictionary) -> Callable:
	var cell_index: int = params.get("cell_index", 0)
	var value_source: String = params.get("value_source", "")  # Variable or literal
	
	return func(_android, state: Dictionary) -> Dictionary:
		print("    [Execute] WRITE_MEMORY [%d] <- %s" % [cell_index, value_source])
		# Get value from variable or use literal
		var value = state["variables"].get(value_source, 0)
		if cell_index >= 0 and cell_index < state["memory"].size():
			state["memory"][cell_index] = value
		return {"continue": true, "jump_to": -1}


## Creates a READ_MEMORY instruction executor.
func _create_memory_read_executor(params: Dictionary) -> Callable:
	var cell_index: int = params.get("cell_index", 0)
	var store_in: String = params.get("store_in", "temp")
	
	return func(_android, state: Dictionary) -> Dictionary:
		print("    [Execute] READ_MEMORY [%d] -> %s" % [cell_index, store_in])
		if cell_index >= 0 and cell_index < state["memory"].size():
			state["variables"][store_in] = state["memory"][cell_index]
		return {"continue": true, "jump_to": -1}


## Creates a no-op executor for unknown instructions.
func _create_noop_executor() -> Callable:
	return func(_android, _state: Dictionary) -> Dictionary:
		print("    [Execute] NOOP")
		return {"continue": true, "jump_to": -1}


## Evaluates a condition for a CONDITION instruction.
func _evaluate_condition(condition_type: String, android) -> bool:
	match condition_type:
		"IS_HEALTH_LOW":
			return android.get_health_percentage() < 0.25
		"IS_HEALTH_HIGH":
			return android.get_health_percentage() > 0.75
		"IS_ENEMY_NEAR":
			# Placeholder - would check proximity sensor
			return false
		"TRUE":
			return true
		"FALSE":
			return false
		_:
			push_warning("[AITranslationService] Unknown condition type: %s" % condition_type)
			return false


## Creates an error result dictionary.
func _create_error_result(error_message: String) -> Dictionary:
	return {
		"success": false,
		"error": error_message,
		"instructions": [],
		"label_map": {}
	}
