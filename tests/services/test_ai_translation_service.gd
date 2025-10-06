## Unit tests for AITranslationService.
## Tests the Visitor pattern implementation for Program translation.
extends GdUnitTestSuite


const TranslationServiceScript = preload("res://src/services/ai_translation_service.gd")
const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")


class EventBusStub:
	extends Node
	signal translation_completed(executable_script)


var translation_service
var event_bus_stub
var _translation_completed_emitted: bool = false


func before_test() -> void:
	translation_service = TranslationServiceScript.new()
	event_bus_stub = EventBusStub.new()
	translation_service.set_event_bus_override(event_bus_stub)
	_translation_completed_emitted = false


func after_test() -> void:
	if translation_service:
		translation_service.set_event_bus_override(null)
		translation_service.queue_free()
		translation_service = null
	if event_bus_stub:
		event_bus_stub.queue_free()
		event_bus_stub = null


func test_translate_null_program_returns_error() -> void:
	var result: Dictionary = translation_service.translate_program(null)
	
	assert_bool(result["success"]).is_false()
	assert_str(result["error"]).is_not_empty()


func test_translate_invalid_program_returns_error() -> void:
	var program = ProgramScript.new()
	# Empty program is invalid
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_false()


func test_translate_simple_program_succeeds() -> void:
	var program = ProgramScript.new("Simple Program")
	program.add_instruction(InstructionScript.new("SET_VARIABLE", -1, {
		"target": "speed",
		"value": 10
	}))
	program.add_instruction(InstructionScript.new("FIRE_WEAPON", 2))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_str(result["error"]).is_empty()
	assert_str(result["program_name"]).is_equal("Simple Program")
	assert_array(result["instructions"]).has_size(2)


func test_translate_builds_label_map() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("SET_TARGET_VELOCITY", 2, {
		"velocity": Vector2(10, 0)
	}))
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "LOOP"}))
	program.add_instruction(InstructionScript.new("FIRE_WEAPON", 2))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_dict(result["label_map"]).contains_key_value("START", 0)
	assert_dict(result["label_map"]).contains_key_value("LOOP", 2)


func test_translate_jump_if_instruction() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("JUMP_IF", -1, {
		"condition": {"operator": "is_true", "lhs": true},
		"target_label": "START"
	}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	var jump_instruction: Dictionary = result["instructions"][1]
	assert_str(jump_instruction["type"]).is_equal("JUMP_IF")


func test_translated_instruction_has_execute_callback() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("SET_TARGET_VELOCITY", 2, {
		"velocity": Vector2(0, 1)
	}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	var translated_instr: Dictionary = result["instructions"][0]
	assert_object(translated_instr.get("execute")).is_not_null()


func test_translated_instruction_preserves_metadata() -> void:
	var program = ProgramScript.new()
	var instruction = InstructionScript.new("SET_TARGET_VELOCITY", 2, {
		"velocity": Vector2(-1, 0),
		"blend": 0.5
	}, "VEL_123")
	program.add_instruction(instruction)
	
	var result: Dictionary = translation_service.translate_program(program)
	
	var translated: Dictionary = result["instructions"][0]
	assert_str(translated["type"]).is_equal("SET_TARGET_VELOCITY")
	assert_str(translated["instruction_id"]).is_equal("VEL_123")
	assert_int(translated["cpu_cost"]).is_equal(2)
	assert_dict(translated["parameters"]).contains_key("velocity")


func test_translate_vector_operation() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("VECTOR_OP", 1, {
		"operation": "add",
		"vector_a": Vector2(1, 0),
		"vector_b": Vector2(0, 1),
		"store_in": "result"
	}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_array(result["instructions"]).has_size(1)
	assert_str(result["instructions"][0]["type"]).is_equal("VECTOR_OP")




func test_translate_jump_if_condition() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "RETREAT"}))
	program.add_instruction(InstructionScript.new("JUMP_IF", -1, {
		"condition": {
			"operator": "<",
			"lhs": {"type": "variable", "name": "health"},
			"rhs": 25
		},
		"target_label": "RETREAT"
	}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	var jump_if: Dictionary = result["instructions"][1]
	assert_str(jump_if["type"]).is_equal("JUMP_IF")


func test_translate_unknown_instruction_type() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("UNKNOWN_TYPE", 1))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	# Should still succeed but with warning
	assert_bool(result["success"]).is_true()
	assert_array(result["instructions"]).has_size(1)


func test_translate_emits_event_on_success() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("DEBUG_LOG", 0, {"message": "translated"}))
	
	event_bus_stub.translation_completed.connect(Callable(self, "_on_translation_completed"))
	translation_service.translate_program(program)
	
	await await_idle_frame()
	
	assert_bool(_translation_completed_emitted).is_true()
	event_bus_stub.translation_completed.disconnect(Callable(self, "_on_translation_completed"))


func _on_translation_completed(_exec: Dictionary) -> void:
	_translation_completed_emitted = true
