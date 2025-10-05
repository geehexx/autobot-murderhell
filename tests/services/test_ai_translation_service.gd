## Unit tests for AITranslationService.
## Tests the Visitor pattern implementation for Program translation.
extends GdUnitTestSuite


const TranslationServiceScript = preload("res://src/services/ai_translation_service.gd")
const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")


var translation_service


func before_test() -> void:
	translation_service = TranslationServiceScript.new()


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
	program.add_instruction(InstructionScript.new("MOVE", 1, {"direction": "forward"}))
	program.add_instruction(InstructionScript.new("ATTACK", 2))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_str(result["error"]).is_empty()
	assert_str(result["program_name"]).is_equal("Simple Program")
	assert_array(result["instructions"]).has_size(2)


func test_translate_builds_label_map() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("MOVE", 1))
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "LOOP"}))
	program.add_instruction(InstructionScript.new("ATTACK", 2))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_dict(result["label_map"]).contains_key_value("START", 0)
	assert_dict(result["label_map"]).contains_key_value("LOOP", 2)


func test_translate_goto_instruction() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "START"}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	var goto_instruction: Dictionary = result["instructions"][1]
	assert_str(goto_instruction["type"]).is_equal("GOTO")


func test_translated_instruction_has_execute_callback() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("MOVE", 1))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	var translated_instr: Dictionary = result["instructions"][0]
	assert_object(translated_instr.get("execute")).is_not_null()


func test_translated_instruction_preserves_metadata() -> void:
	var program = ProgramScript.new()
	var instruction = InstructionScript.new("MOVE", 3, {"direction": "left"}, "MOVE_123")
	program.add_instruction(instruction)
	
	var result: Dictionary = translation_service.translate_program(program)
	
	var translated: Dictionary = result["instructions"][0]
	assert_str(translated["type"]).is_equal("MOVE")
	assert_str(translated["instruction_id"]).is_equal("MOVE_123")
	assert_int(translated["cpu_cost"]).is_equal(3)
	assert_dict(translated["parameters"]).contains_key_value("direction", "left")


func test_translate_memory_operations() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("WRITE_MEMORY", 1, {"cell_index": 0, "value_source": "temp"}))
	program.add_instruction(InstructionScript.new("READ_MEMORY", 1, {"cell_index": 0, "store_in": "result"}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	assert_array(result["instructions"]).has_size(2)
	assert_str(result["instructions"][0]["type"]).is_equal("WRITE_MEMORY")
	assert_str(result["instructions"][1]["type"]).is_equal("READ_MEMORY")


func test_translate_condition_instruction() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "RETREAT"}))
	program.add_instruction(InstructionScript.new("CONDITION", 2, {
		"condition_type": "IS_HEALTH_LOW",
		"jump_if_true": "RETREAT",
		"jump_if_false": ""
	}))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	assert_bool(result["success"]).is_true()
	var condition: Dictionary = result["instructions"][1]
	assert_str(condition["type"]).is_equal("CONDITION")


func test_translate_unknown_instruction_type() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("UNKNOWN_TYPE", 1))
	
	var result: Dictionary = translation_service.translate_program(program)
	
	# Should still succeed but with warning
	assert_bool(result["success"]).is_true()
	assert_array(result["instructions"]).has_size(1)


func test_translate_emits_event_on_success() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("MOVE", 1))
	
	var signal_emitted: bool = false
	var signal_handler: Callable = func(_exec: Dictionary) -> void:
		signal_emitted = true
	
	EventBus.translation_completed.connect(signal_handler)
	translation_service.translate_program(program)
	
	await await_idle_frame()
	
	assert_bool(signal_emitted).is_true()
	EventBus.translation_completed.disconnect(signal_handler)
