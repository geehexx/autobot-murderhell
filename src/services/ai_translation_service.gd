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
		"SET_VARIABLE":
			translated["execute"] = _create_set_variable_executor(instruction.parameters)
		"MATH_OP":
			translated["execute"] = _create_math_op_executor(instruction.parameters)
		"VECTOR_OP":
			translated["execute"] = _create_vector_op_executor(instruction.parameters)
		"GET_SENSOR_DATA":
			translated["execute"] = _create_get_sensor_data_executor(instruction.parameters)
		"DEBUG_LOG":
			translated["execute"] = _create_debug_log_executor(instruction.parameters)
		"LABEL":
			translated["execute"] = _create_label_executor()
		"JUMP_IF":
			translated["execute"] = _create_jump_if_executor(instruction.parameters, label_map)
		"SET_TARGET_VELOCITY":
			translated["execute"] = _create_set_target_velocity_executor(instruction.parameters)
		"SET_ROTATION_TARGET":
			translated["execute"] = _create_set_rotation_target_executor(instruction.parameters)
		"FIRE_WEAPON":
			translated["execute"] = _create_fire_weapon_executor(instruction.parameters)
		_:
			push_warning("[AITranslationService] Unknown instruction type: %s" % instruction.type)
			translated["execute"] = _create_noop_executor()
	
	return translated


## Creates a SET_VARIABLE instruction executor.
func _create_set_variable_executor(params: Dictionary) -> Callable:
	var target: String = params.get("target", "")
	var value = params.get("value", null)
	var source = params.get("source", null)
	
	return func(_android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		if target.is_empty():
			push_warning("[AITranslationService] SET_VARIABLE missing 'target'")
			return {"continue": true, "jump_to": -1}
		var resolved = null
		if source != null:
			resolved = _resolve_value(source, state)
		else:
			resolved = _resolve_value(value, state)
		state["variables"][target] = resolved
		return {"continue": true, "jump_to": -1}


## Creates a MATH_OP instruction executor.
func _create_math_op_executor(params: Dictionary) -> Callable:
	var operation: String = str(params.get("operation", "add")).to_lower()
	var lhs = params.get("lhs", 0)
	var rhs = params.get("rhs", 0)
	var store_in: String = params.get("store_in", "")
	
	return func(_android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		if store_in.is_empty():
			push_warning("[AITranslationService] MATH_OP missing 'store_in'")
			return {"continue": true, "jump_to": -1}
		var lhs_value = _resolve_numeric(lhs, state)
		var rhs_value = _resolve_numeric(rhs, state)
		if lhs_value == null or rhs_value == null:
			push_warning("[AITranslationService] MATH_OP operands must resolve to numbers")
			return {"continue": true, "jump_to": -1}
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
					push_warning("[AITranslationService] MATH_OP division by zero")
					return {"continue": true, "jump_to": -1}
				result = lhs_value / rhs_value
			_:
				push_warning("[AITranslationService] MATH_OP unknown operation '%s'" % operation)
				return {"continue": true, "jump_to": -1}
		state["variables"][store_in] = result
		return {"continue": true, "jump_to": -1}


## Creates a VECTOR_OP instruction executor.
func _create_vector_op_executor(params: Dictionary) -> Callable:
	var operation: String = str(params.get("operation", "add")).to_lower()
	var vector_a = params.get("vector_a", Vector2.ZERO)
	var vector_b = params.get("vector_b", Vector2.ZERO)
	var scalar = params.get("scalar", 1.0)
	var store_in: String = params.get("store_in", "")
	
	return func(_android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		if store_in.is_empty():
			push_warning("[AITranslationService] VECTOR_OP missing 'store_in'")
			return {"continue": true, "jump_to": -1}
		var a_value: Vector2 = _resolve_vector(vector_a, state)
		var b_value: Vector2 = _resolve_vector(vector_b, state)
		var scalar_value: float = _resolve_numeric(scalar, state)
		if scalar_value == null:
			scalar_value = 1.0
		var result: Vector2 = Vector2.ZERO
		match operation:
			"add":
				result = a_value + b_value
			"subtract":
				result = a_value - b_value
			"normalize":
				result = a_value.normalized()
			"scale":
				result = a_value * scalar_value
			_:
				push_warning("[AITranslationService] VECTOR_OP unknown operation '%s'" % operation)
				return {"continue": true, "jump_to": -1}
		state["variables"][store_in] = result
		return {"continue": true, "jump_to": -1}


## Creates a GET_SENSOR_DATA instruction executor.
func _create_get_sensor_data_executor(params: Dictionary) -> Callable:
	var sensor: String = str(params.get("sensor", "")).to_upper()
	var store_in: String = params.get("store_in", "")

	return func(android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		if store_in.is_empty():
			push_warning("[AITranslationService] GET_SENSOR_DATA missing 'store_in'")
			return {"continue": true, "jump_to": -1}
		var value = null
		match sensor:
			"SELF_POSITION":
				if android and android.has_method("get"):
					var maybe_position = android.get("global_position")
					value = maybe_position if maybe_position is Vector2 else Vector2.ZERO
				else:
					value = Vector2.ZERO
			"SELF_ROTATION":
				if android and android.has_method("get"):
					var maybe_rotation = android.get("rotation")
					value = maybe_rotation if typeof(maybe_rotation) == TYPE_FLOAT else 0.0
				else:
					value = 0.0
			"TARGET_VELOCITY":
				if android and android.has_method("get"):
					var maybe_velocity = android.get("target_velocity")
					value = maybe_velocity if maybe_velocity is Vector2 else Vector2.ZERO
				else:
					value = Vector2.ZERO
			_:
				value = null
		state["variables"][store_in] = value
		return {"continue": true, "jump_to": -1}


## Creates a DEBUG_LOG instruction executor.
func _create_debug_log_executor(params: Dictionary) -> Callable:
	var message: String = str(params.get("message", ""))
	var values = params.get("values", [])

	return func(_android, state: Dictionary) -> Dictionary:
		var resolved: Array = []
		if values is Array:
			for entry in values:
				resolved.append(_resolve_value(entry, state))
		print("    [Execute] DEBUG_LOG %s %s" % [message, resolved])
		return {"continue": true, "jump_to": -1}


## Creates a LABEL instruction executor.
func _create_label_executor() -> Callable:
	return func(_android, _state: Dictionary) -> Dictionary:
		return {"continue": true, "jump_to": -1}


## Creates a JUMP_IF instruction executor.
func _create_jump_if_executor(params: Dictionary, label_map: Dictionary) -> Callable:
	var target_label: String = params.get("target_label", "")
	var else_label: String = params.get("else_label", "")
	var negate: bool = params.get("negate", false)
	var condition_data = params.get("condition", null)

	return func(_android, state: Dictionary) -> Dictionary:
		var condition_met: bool = _evaluate_condition(condition_data, state)
		if negate:
			condition_met = not condition_met
		if condition_met:
			return {"continue": true, "jump_to": label_map.get(target_label, -1)}
		if not else_label.is_empty():
			return {"continue": true, "jump_to": label_map.get(else_label, -1)}
		return {"continue": true, "jump_to": -1}


## Creates a SET_TARGET_VELOCITY instruction executor.
func _create_set_target_velocity_executor(params: Dictionary) -> Callable:
	var velocity_raw = params.get("velocity", Vector2.ZERO)
	var blend_raw = params.get("blend", 1.0)

	return func(android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		var velocity: Vector2 = _resolve_vector(velocity_raw, state)
		var blend_value: float = _resolve_numeric(blend_raw, state)
		if blend_value == null:
			blend_value = 1.0
		blend_value = clamp(blend_value, 0.0, 1.0)
		if android and android.has_method("set"):
			android.set("target_velocity", velocity)
			android.set("velocity_blend", blend_value)
		state["variables"]["target_velocity"] = velocity
		return {"continue": true, "jump_to": -1}


## Creates a SET_ROTATION_TARGET instruction executor.
func _create_set_rotation_target_executor(params: Dictionary) -> Callable:
	var rotation_raw = params.get("rotation_deg", 0.0)

	return func(android, state: Dictionary) -> Dictionary:
		_ensure_state_defaults(state)
		var rotation_value: float = _resolve_numeric(rotation_raw, state)
		if rotation_value == null:
			rotation_value = 0.0
		if android and android.has_method("set"):
			android.set("rotation_target_deg", rotation_value)
		state["variables"]["rotation_target_deg"] = rotation_value
		return {"continue": true, "jump_to": -1}


## Creates a FIRE_WEAPON instruction executor.
func _create_fire_weapon_executor(_params: Dictionary) -> Callable:
	return func(android, _state: Dictionary) -> Dictionary:
		if android and android.has_method("fire_weapon"):
			android.fire_weapon()
		else:
			print("    [Execute] FIRE_WEAPON (no fire_weapon method)")
		return {"continue": true, "jump_to": -1}


## Creates a no-op executor for unknown instructions.
func _create_noop_executor() -> Callable:
	return func(_android, _state: Dictionary) -> Dictionary:
		print("    [Execute] NOOP")
		return {"continue": true, "jump_to": -1}


func _ensure_state_defaults(state: Dictionary) -> void:
	if not state.has("variables") or typeof(state["variables"]) != TYPE_DICTIONARY:
		state["variables"] = {}
	if not state.has("memory") or typeof(state["memory"]) != TYPE_ARRAY:
		state["memory"] = []


func _resolve_value(raw, state: Dictionary):
	if raw == null:
		return null
	if typeof(raw) == TYPE_STRING:
		if state.has("variables") and state["variables"].has(raw):
			return state["variables"][raw]
		if raw.is_valid_float():
			return raw.to_float()
		return raw
	if typeof(raw) == TYPE_DICTIONARY:
		var dict: Dictionary = raw
		var variant_type: String = str(dict.get("type", "literal")).to_lower()
		match variant_type:
			"variable":
				return state.get("variables", {}).get(dict.get("name", ""), null)
			"vector":
				return Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
			"literal":
				return dict.get("value")
		return dict.get("value", null)
	return raw


func _resolve_numeric(raw, state: Dictionary) -> float:
	var value = _resolve_value(raw, state)
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_BOOL:
			return 1.0 if value else 0.0
		TYPE_STRING:
			return value.to_float() if value.is_valid_float() else null
	return null


func _resolve_vector(raw, state: Dictionary) -> Vector2:
	var value = _resolve_value(raw, state)
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_ARRAY:
			if value.size() >= 2:
				return Vector2(value[0], value[1])
		TYPE_DICTIONARY:
			return Vector2(value.get("x", 0.0), value.get("y", 0.0))
	return Vector2.ZERO


func _evaluate_condition(condition_data, state: Dictionary) -> bool:
	if condition_data == null:
		return false
	if typeof(condition_data) == TYPE_BOOL:
		return condition_data
	if typeof(condition_data) != TYPE_DICTIONARY:
		return bool(_resolve_value(condition_data, state))
	if condition_data.is_empty():
		return false

	var comparator: String = str(condition_data.get("operator", "==")).to_lower()
	var lhs_raw = condition_data.get("lhs")
	var rhs_raw = condition_data.get("rhs")

	match comparator:
		"==", "equals":
			return _resolve_value(lhs_raw, state) == _resolve_value(rhs_raw, state)
		"!=", "not_equals":
			return _resolve_value(lhs_raw, state) != _resolve_value(rhs_raw, state)
		">", "greater_than":
			return _compare_numeric(lhs_raw, rhs_raw, state, func(a, b): return a > b)
		"<", "less_than":
			return _compare_numeric(lhs_raw, rhs_raw, state, func(a, b): return a < b)
		">=", "greater_or_equal":
			return _compare_numeric(lhs_raw, rhs_raw, state, func(a, b): return a >= b)
		"<=", "less_or_equal":
			return _compare_numeric(lhs_raw, rhs_raw, state, func(a, b): return a <= b)
		"is_true":
			return bool(_resolve_value(lhs_raw, state))
		"is_false":
			return not bool(_resolve_value(lhs_raw, state))
	return false


func _compare_numeric(lhs_raw, rhs_raw, state: Dictionary, comparator: Callable) -> bool:
	var lhs_value = _resolve_numeric(lhs_raw, state)
	var rhs_value = _resolve_numeric(rhs_raw, state)
	if lhs_value == null or rhs_value == null:
		push_warning("[AITranslationService] Numeric comparison received non-numeric values")
		return false
	return comparator.call(lhs_value, rhs_value)


## Creates an error result dictionary.
func _create_error_result(error_message: String) -> Dictionary:
	return {
		"success": false,
		"error": error_message,
		"instructions": [],
		"label_map": {}
	}
