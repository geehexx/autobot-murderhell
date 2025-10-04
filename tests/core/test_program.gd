## Unit tests for the Program class (Programming Context aggregate root).
## Following TDD-first approach as specified in the charter.
extends GdUnitTestSuite


func test_program_creation_with_defaults() -> void:
	var program: Program = Program.new()
	
	assert_str(program.program_name).is_equal("Untitled Program")
	assert_array(program.instructions).is_empty()
	assert_dict(program.variables).is_empty()
	assert_int(program.max_memory_cells).is_equal(4)
	assert_array(program.memory_cells).has_size(4)


func test_program_creation_with_parameters() -> void:
	var program: Program = Program.new("Test Program", 8)
	
	assert_str(program.program_name).is_equal("Test Program")
	assert_int(program.max_memory_cells).is_equal(8)
	assert_array(program.memory_cells).has_size(8)


func test_add_valid_instruction() -> void:
	var program: Program = Program.new()
	var instruction: Instruction = Instruction.new("MOVE", 1)
	
	program.add_instruction(instruction)
	
	assert_array(program.instructions).has_size(1)
	assert_object(program.instructions[0]).is_equal(instruction)


func test_add_invalid_instruction_is_ignored() -> void:
	var program: Program = Program.new()
	var invalid_instruction: Instruction = Instruction.new("", 0)  # Invalid
	
	program.add_instruction(invalid_instruction)
	
	assert_array(program.instructions).is_empty()


func test_insert_instruction_at_beginning() -> void:
	var program: Program = Program.new()
	var instruction1: Instruction = Instruction.new("MOVE", 1, {}, "I1")
	var instruction2: Instruction = Instruction.new("ATTACK", 2, {}, "I2")
	
	program.add_instruction(instruction1)
	program.insert_instruction(instruction2, 0)
	
	assert_array(program.instructions).has_size(2)
	assert_str(program.instructions[0].instruction_id).is_equal("I2")
	assert_str(program.instructions[1].instruction_id).is_equal("I1")


func test_insert_instruction_at_end() -> void:
	var program: Program = Program.new()
	var instruction1: Instruction = Instruction.new("MOVE", 1, {}, "I1")
	var instruction2: Instruction = Instruction.new("ATTACK", 2, {}, "I2")
	
	program.add_instruction(instruction1)
	program.insert_instruction(instruction2, 1)
	
	assert_array(program.instructions).has_size(2)
	assert_str(program.instructions[1].instruction_id).is_equal("I2")


func test_remove_instruction_at_valid_index() -> void:
	var program: Program = Program.new()
	var instruction: Instruction = Instruction.new("MOVE", 1)
	program.add_instruction(instruction)
	
	var result: bool = program.remove_instruction(0)
	
	assert_bool(result).is_true()
	assert_array(program.instructions).is_empty()


func test_remove_instruction_at_invalid_index() -> void:
	var program: Program = Program.new()
	
	var result: bool = program.remove_instruction(0)
	
	assert_bool(result).is_false()


func test_get_total_cpu_cost() -> void:
	var program: Program = Program.new()
	program.add_instruction(Instruction.new("MOVE", 2))
	program.add_instruction(Instruction.new("ATTACK", 3))
	program.add_instruction(Instruction.new("SCAN", 1))
	
	var total_cost: int = program.get_total_cpu_cost()
	
	assert_int(total_cost).is_equal(6)


func test_get_total_cpu_cost_empty_program() -> void:
	var program: Program = Program.new()
	
	var total_cost: int = program.get_total_cpu_cost()
	
	assert_int(total_cost).is_equal(0)


func test_validate_empty_program_is_invalid() -> void:
	var program: Program = Program.new()
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_array(result["errors"]).contains("Program has no instructions")


func test_validate_program_with_valid_instructions() -> void:
	var program: Program = Program.new()
	program.add_instruction(Instruction.new("MOVE", 1))
	program.add_instruction(Instruction.new("ATTACK", 2))
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_true()
	assert_array(result["errors"]).is_empty()


func test_validate_program_with_invalid_instruction() -> void:
	var program: Program = Program.new()
	var valid: Instruction = Instruction.new("MOVE", 1)
	var invalid: Instruction = Instruction.new("", 0)
	
	# Manually add invalid instruction (bypassing add_instruction validation)
	program.instructions.append(valid)
	program.instructions.append(invalid)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_array(result["errors"]).is_not_empty()


func test_validate_goto_with_missing_label() -> void:
	var program: Program = Program.new()
	var goto_instruction: Instruction = Instruction.new("GOTO", 1, {"label": "START"})
	program.add_instruction(goto_instruction)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_false()
	assert_str(str(result["errors"])).contains("non-existent label")


func test_validate_goto_with_existing_label() -> void:
	var program: Program = Program.new()
	var label: Instruction = Instruction.new("LABEL", 0, {"name": "START"})
	var goto_instruction: Instruction = Instruction.new("GOTO", 1, {"label": "START"})
	
	program.add_instruction(label)
	program.add_instruction(goto_instruction)
	
	var result: Dictionary = program.validate()
	
	assert_bool(result["is_valid"]).is_true()


func test_duplicate_program_creates_independent_copy() -> void:
	var original: Program = Program.new("Original", 4)
	original.add_instruction(Instruction.new("MOVE", 1))
	original.variables["counter"] = 0
	original.memory_cells[0] = 42
	
	var copy: Program = original.duplicate_program()
	
	# Verify same values
	assert_str(copy.program_name).is_equal("Original")
	assert_int(copy.max_memory_cells).is_equal(4)
	assert_array(copy.instructions).has_size(1)
	assert_int(copy.memory_cells[0]).is_equal(42)
	
	# Verify independence
	copy.program_name = "Copy"
	copy.memory_cells[0] = 99
	copy.variables["counter"] = 10
	
	assert_str(original.program_name).is_equal("Original")
	assert_int(original.memory_cells[0]).is_equal(42)
	assert_int(original.variables["counter"]).is_equal(0)


func test_program_to_string_contains_key_information() -> void:
	var program: Program = Program.new("Test Program", 4)
	program.add_instruction(Instruction.new("MOVE", 2))
	
	var result: String = program.to_string()
	
	assert_str(result).contains("Test Program")
	assert_str(result).contains("CPU Cost: 2")
	assert_str(result).contains("Memory Cells: 4")
	assert_str(result).contains("MOVE")
