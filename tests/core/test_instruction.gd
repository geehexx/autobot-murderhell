## Unit tests for the Instruction class.
## Following TDD-first approach as specified in the charter.
extends GdUnitTestSuite


const InstructionScript = preload("res://src/core/instruction.gd")


func test_instruction_creation_with_defaults() -> void:
	var instruction = InstructionScript.new()
	
	assert_str(instruction.type).is_empty()
	assert_int(instruction.cpu_cost).is_equal(0)
	assert_dict(instruction.parameters).is_empty()
	assert_str(instruction.instruction_id).is_not_empty()


func test_instruction_creation_with_parameters() -> void:
	var params: Dictionary = {"target": "speed", "value": 5}
	var instruction = InstructionScript.new("SET_VARIABLE", -1, params, "SET_001")
	
	assert_str(instruction.type).is_equal("SET_VARIABLE")
	assert_int(instruction.cpu_cost).is_equal(1)
	assert_dict(instruction.parameters).contains_key_value("target", "speed")
	assert_dict(instruction.parameters).contains_key_value("value", 5)
	assert_str(instruction.instruction_id).is_equal("SET_001")


func test_instruction_validation_empty_type_is_invalid() -> void:
	var instruction = InstructionScript.new("", 1)
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_unknown_type_is_invalid() -> void:
	var instruction = InstructionScript.new("UNKNOWN", 1)
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_negative_cpu_cost_is_invalid() -> void:
	var instruction = InstructionScript.new("SET_VARIABLE", -1)
	instruction.cpu_cost = -1
	
	assert_bool(instruction.is_valid()).is_false()


func test_instruction_validation_valid_instruction() -> void:
	var instruction = InstructionScript.new("DEBUG_LOG", 0, {"message": "Hello"})
	
	assert_bool(instruction.is_valid()).is_true()


func test_instruction_get_description_without_parameters() -> void:
	var instruction = InstructionScript.new("FIRE_WEAPON", 2, {}, "FIRE_001")
	var result: String = instruction.get_description()
	
	assert_str(result).contains("FIRE_001")
	assert_str(result).contains("FIRE_WEAPON")
	assert_str(result).contains("CPU: 2")


func test_instruction_get_description_with_parameters() -> void:
	var params: Dictionary = {"target": "speed", "value": 10}
	var instruction = InstructionScript.new("SET_VARIABLE", -1, params, "SET_001")
	var result: String = instruction.get_description()
	
	assert_str(result).contains("SET_001")
	assert_str(result).contains("SET_VARIABLE")
	assert_str(result).contains("target")



func test_instruction_duplicate_creates_independent_copy() -> void:
	var params: Dictionary = {"target": "speed", "value": 10}
	var original = InstructionScript.new("SET_VARIABLE", -1, params, "SET_001")
	var copy = original.duplicate_instruction()
	
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
	var instruction1 = InstructionScript.new("SET_VARIABLE")
	var instruction2 = InstructionScript.new("SET_VARIABLE")
	
	assert_str(instruction1.instruction_id).is_not_equal(instruction2.instruction_id)
