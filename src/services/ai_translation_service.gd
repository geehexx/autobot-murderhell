## AI Translation Service
## Translates visual block Programs into executable logic.
## This is the core service that bridges the Programming and Simulation contexts.
extends Node

# Preload required classes
const InstructionScript = preload("res://src/core/instruction.gd")
const ProgramScript = preload("res://src/core/program.gd")

var _event_bus_override: Node = null


func _describe_event_bus(bus: Node) -> String:
	if bus == null:
		return "null"
	var descriptor := []
	descriptor.append(bus.get_class())
	if bus.name != "":
		descriptor.append(bus.name)
	if bus.is_inside_tree():
		descriptor.append(str(bus.get_path()))
	return "::".join(descriptor)


func _resolve_event_bus() -> Node:
	if _event_bus_override:
		return _event_bus_override
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	if typeof(EventBus) == TYPE_OBJECT:
		return EventBus
	return null


func set_event_bus_override(bus: Node) -> void:
	_event_bus_override = bus
	if bus:
		print("[AITranslationService] EventBus override set: %s" % _describe_event_bus(bus))
	else:
		print("[AITranslationService] EventBus override cleared")


func translate_program(program) -> Dictionary:
	if not program:
		push_error("[AITranslationService] Cannot translate null program")
		return _create_error_result("Null program")

	var validation: Dictionary = program.validate()
	if not validation["is_valid"]:
		if _errors_are_translatable(validation["errors"]):
			push_warning("[AITranslationService] Translating program with non-blocking issues: %s" % str(validation["errors"]))
		else:
			push_error("[AITranslationService] Translation failed - invalid program: %s" % str(validation["errors"]))
			return _create_error_result(str(validation["errors"]))

	print("[AITranslationService] Translating program: %s" % program.program_name)

	var executable: Dictionary = {
		"program_name": program.program_name,
		"instructions": [],
		"label_map": {},
		"success": true,
		"error": ""
	}

	for i in program.instructions.size():
		var instruction = program.instructions[i]
		if instruction.type == "LABEL":
			var label_name: String = instruction.parameters.get("name", "")
			executable["label_map"][label_name] = i

	for instruction in program.instructions:
		var translated: Dictionary = _translate_instruction(instruction, executable["label_map"])
		executable["instructions"].append(translated)

	print("[AITranslationService] Translation complete: %d instructions" % executable["instructions"].size())

	var event_bus := _resolve_event_bus()
	if event_bus and event_bus.has_signal("translation_completed"):
		var connections := []
		if event_bus.has_method("get_signal_connection_list"):
			connections = event_bus.get_signal_connection_list("translation_completed")
		print("[AITranslationService] Emitting translation_completed via: %s" % _describe_event_bus(event_bus))
		event_bus.emit_signal("translation_completed", executable)
		for connection_info in connections:
			if not connection_info.has("callable"):
				continue
			var callable: Callable = connection_info["callable"]
			var descriptor: String = String(callable.get_method())
			if callable.get_object():
				descriptor = "%s::%s" % [callable.get_object().get_class(), callable.get_method()]
			else:
				descriptor = "lambda::%s" % descriptor
			if not callable.is_valid():
				push_warning("[AITranslationService] Skipping invalid callable for translation_completed: %s" % descriptor)
			elif callable.get_object() == null:
				# Emitted lambda callables do not receive automatic invocation; trigger manually.
				callable.callv([executable.duplicate(true)])
	else:
		print("[AITranslationService] EventBus missing translation_completed signal; emission skipped")

	return executable


func _errors_are_translatable(errors: Array) -> bool:
	if errors.is_empty():
		return false
	for error in errors:
		var message := str(error).to_lower()
		var allowed := false
		if "invalid definition" in message:
			allowed = true
		elif "unknown type" in message:
			allowed = true
		if not allowed:
			return false
	return true


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
