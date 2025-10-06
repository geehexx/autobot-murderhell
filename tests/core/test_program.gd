## Unit tests for the Program class (Programming Context aggregate root).
## Following TDD-first approach as specified in the charter.
extends GdUnitTestSuite


const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")


func test_program_creation_with_defaults() -> void:
	var program = ProgramScript.new()
	
	assert_str(program.program_name).is_equal("Untitled Program")
	assert_array(program.instructions).is_empty()
	assert_dict(program.blackboard_defaults).is_empty()
	assert_int(program.cpu_budget_per_tick).is_equal(100)


func test_program_creation_with_parameters() -> void:
	var program = ProgramScript.new("Test Program", 150)
	
	assert_str(program.program_name).is_equal("Test Program")
	assert_int(program.cpu_budget_per_tick).is_equal(150)


func test_add_valid_instruction() -> void:
	var program = ProgramScript.new()
	var instruction = InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 10})
	
	program.add_instruction(instruction)
	
	assert_array(program.instructions).has_size(1)
	assert_object(program.instructions[0]).is_equal(instruction)


func test_add_invalid_instruction_is_ignored() -> void:
	var program = ProgramScript.new()
	var invalid_instruction = InstructionScript.new("", 0)
	
	program.add_instruction(invalid_instruction)
	
	assert_array(program.instructions).is_empty()


func test_insert_instruction_at_beginning() -> void:
	var program = ProgramScript.new()
	var instruction1 = InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5}, "I1")
	var instruction2 = InstructionScript.new("DEBUG_LOG", 0, {"message": "Start"}, "I2")
	
	program.add_instruction(instruction1)
	program.insert_instruction(instruction2, 0)
	
	assert_array(program.instructions).has_size(2)
	assert_str(program.instructions[0].instruction_id).is_equal("I2")
	assert_str(program.instructions[1].instruction_id).is_equal("I1")


func test_insert_instruction_at_end() -> void:
	var program = ProgramScript.new()
	var instruction1 = InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5}, "I1")
	var instruction2 = InstructionScript.new("DEBUG_LOG", 0, {"message": "Done"}, "I2")
	
	program.add_instruction(instruction1)
	program.insert_instruction(instruction2, 1)
	
	assert_array(program.instructions).has_size(2)
	assert_str(program.instructions[1].instruction_id).is_equal("I2")


func test_remove_instruction_at_valid_index() -> void:
	var program = ProgramScript.new()
	var instruction = InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5})
	program.add_instruction(instruction)
	
	var result: bool = program.remove_instruction(0)
	
	assert_bool(result).is_true()
	assert_array(program.instructions).is_empty()


func test_remove_instruction_at_invalid_index() -> void:
	var program = ProgramScript.new()
	
	var result: bool = program.remove_instruction(0)
	
	assert_bool(result).is_false()


func test_get_total_cpu_cost() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5}))
	program.add_instruction(InstructionScript.new("JUMP_IF", -1, {
		"condition": {"operator": "is_true", "lhs": true},
		"target_label": "LOOP"
	}))
	program.add_instruction(InstructionScript.new("FIRE_WEAPON", 2))
	
	var total_cost: int = program.get_total_cpu_cost()
	
	assert_int(total_cost).is_equal(4)


func test_get_total_cpu_cost_empty_program() -> void:
	var program = ProgramScript.new()
	
	var total_cost: int = program.get_total_cpu_cost()
	
	assert_int(total_cost).is_equal(0)


func test_validate_empty_program_is_invalid() -> void:
	var program = ProgramScript.new()
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_array(result["errors"]).contains("Program has no instructions")


func test_validate_program_with_valid_instructions() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 10}))
	program.add_instruction(InstructionScript.new("DEBUG_LOG", 0, {"message": "Done"}))
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_true()
	assert_array(result["errors"]).is_empty()


func test_validate_program_with_invalid_instruction() -> void:
	var program = ProgramScript.new()
	var valid = InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 10})
	var invalid = InstructionScript.new("", 0)
	
	# Manually add invalid instruction (bypassing add_instruction validation)
	program.instructions.append(valid)
	program.instructions.append(invalid)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_array(result["errors"]).is_not_empty()


func test_validate_jump_if_with_missing_label() -> void:
	var program = ProgramScript.new()
	var jump_instruction = InstructionScript.new("JUMP_IF", -1, {
		"condition": {"operator": "is_true", "lhs": true},
		"target_label": "START"
	})
	program.add_instruction(jump_instruction)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_str(str(result["errors"])).contains("unknown label")


func test_validate_jump_if_with_existing_label() -> void:
	var program = ProgramScript.new()
	var label = InstructionScript.new("LABEL", 0, {"name": "START"})
	var jump_instruction = InstructionScript.new("JUMP_IF", -1, {
		"condition": {"operator": "is_true", "lhs": true},
		"target_label": "START"
	})
	
	program.add_instruction(label)
	program.add_instruction(jump_instruction)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_true()


func test_duplicate_program_creates_independent_copy() -> void:
	var original = ProgramScript.new("Original", 120)
	original.add_instruction(InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5}))
	original.blackboard_defaults = {"speed": 5}
	
	var copy = original.duplicate_program()
	
	# Verify same values
	assert_str(copy.program_name).is_equal("Original")
	assert_int(copy.cpu_budget_per_tick).is_equal(120)
	assert_array(copy.instructions).has_size(1)
	assert_dict(copy.blackboard_defaults).contains_key_value("speed", 5)
	
	# Verify independence
	copy.program_name = "Copy"
	copy.blackboard_defaults["speed"] = 10
	
	assert_str(original.program_name).is_equal("Original")
	assert_int(original.blackboard_defaults["speed"]).is_equal(5)


func test_program_get_description_contains_key_information() -> void:
	var program = ProgramScript.new("Test Program", 120)
	program.add_instruction(InstructionScript.new("SET_VARIABLE", -1, {"target": "speed", "value": 5}))
	
	var result: String = program.get_description()
	
	assert_str(result).contains("Test Program")
	assert_str(result).contains("CPU Cost: 1")
	assert_str(result).contains("CPU Budget/Tick: 120")
	assert_str(result).contains("SET_VARIABLE")
