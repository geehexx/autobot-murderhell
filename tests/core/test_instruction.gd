## Unit tests for the Instruction class.
## Following TDD-first approach as specified in the charter.
extends GdUnitTestSuite


func test_instruction_creation_with_defaults() -> void:
	var instruction: Instruction = Instruction.new()
	
	assert_str(instruction.type).is_empty()
	assert_int(instruction.cpu_cost).is_equal(1)
	assert_dict(instruction.parameters).is_empty()
	assert_str(instruction.instruction_id).is_not_empty()


func test_instruction_creation_with_parameters() -> void:
	var params: Dictionary = {"direction": "forward", "distance": 5}
	var instruction: Instruction = Instruction.new("MOVE", 2, params, "MOVE_001")
	
	assert_str(instruction.type).is_equal("MOVE")
	assert_int(instruction.cpu_cost).is_equal(2)
	assert_dict(instruction.parameters).contains_key_value("direction", "forward")
	assert_dict(instruction.parameters).contains_key_value("distance", 5)
	assert_str(instruction.instruction_id).is_equal("MOVE_001")


func test_instruction_validation_empty_type_is_invalid() -> void:
	var instruction: Instruction = Instruction.new("", 1)
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_zero_cpu_cost_is_invalid() -> void:
	var instruction: Instruction = Instruction.new("MOVE", 0)
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_negative_cpu_cost_is_invalid() -> void:
	var instruction: Instruction = Instruction.new("MOVE", -1)
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_valid_instruction() -> void:
	var instruction: Instruction = Instruction.new("MOVE", 1)
	
	assert_bool(instruction.is_valid()).is_true()


func test_instruction_to_string_without_parameters() -> void:
	var instruction: Instruction = Instruction.new("MOVE", 2, {}, "MOVE_001")
	var result: String = instruction.to_string()
	
	assert_str(result).contains("MOVE_001")
	assert_str(result).contains("MOVE")
	assert_str(result).contains("CPU: 2")


func test_instruction_to_string_with_parameters() -> void:
	var params: Dictionary = {"direction": "forward"}
	var instruction: Instruction = Instruction.new("MOVE", 2, params, "MOVE_001")
	var result: String = instruction.to_string()
	
	assert_str(result).contains("MOVE_001")
	assert_str(result).contains("MOVE")
	assert_str(result).contains("direction")


func test_instruction_duplicate_creates_independent_copy() -> void:
	var params: Dictionary = {"value": 10}
	var original: Instruction = Instruction.new("TEST", 3, params, "TEST_001")
	var copy: Instruction = original.duplicate_instruction()
	
	# Verify copy has same values
	assert_str(copy.type).is_equal(original.type)
	assert_int(copy.cpu_cost).is_equal(original.cpu_cost)
	assert_str(copy.instruction_id).is_equal(original.instruction_id)
	assert_dict(copy.parameters).contains_key_value("value", 10)
	
	# Verify they are independent (modifying copy doesn't affect original)
	copy.parameters["value"] = 20
	assert_int(original.parameters["value"]).is_equal(10)
	assert_int(copy.parameters["value"]).is_equal(20)


func test_instruction_id_generation_is_unique() -> void:
	var instruction1: Instruction = Instruction.new("MOVE")
	var instruction2: Instruction = Instruction.new("MOVE")
	
	assert_str(instruction1.instruction_id).is_not_equal(instruction2.instruction_id)
