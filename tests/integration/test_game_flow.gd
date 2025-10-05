## Integration Test - Full Game Flow
## Tests the complete user workflow from program creation to execution.
extends GdUnitTestSuite


var suite_attributes := {
    "timeout": 10000
}

# Preload required scripts
const ProgramScript = preload("res://scripts/core/program.gd")
const InstructionScript = preload("res://scripts/core/instruction.gd")
const AITranslationServiceScript = preload("res://scripts/services/ai_translation_service.gd")
const AndroidEntityScript = preload("res://scripts/simulation/android_entity.gd")

var translation_service
var test_android


func before_test() -> void:
	translation_service = AITranslationServiceScript.new()
	add_child(translation_service)


func after_test() -> void:
	if translation_service:
		translation_service.queue_free()
	if test_android:
		test_android.queue_free()


## TEST 1: User creates a simple program
func test_user_creates_simple_move_program() -> void:
	# User creates a new program
	var program = ProgramScript.new("My First Program")
	assert_str(program.program_name).is_equal("My First Program")
	
	# User adds a MOVE instruction
	var move_instr = InstructionScript.new("MOVE", 2, {"direction": "forward", "distance": 50.0})
	program.add_instruction(move_instr)
	
	# Program should have 1 instruction
	assert_int(program.instructions.size()).is_equal(1)
	assert_str(program.instructions[0].type).is_equal("MOVE")
	
	print("[TEST] ✓ User can create a program with a MOVE instruction")


## TEST 2: User creates a program with labels and jumps
func test_user_creates_loop_program() -> void:
	var program = ProgramScript.new("Loop Program")
	
	# Add instructions: LABEL -> MOVE -> GOTO
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("MOVE", 2, {"direction": "forward"}))
	program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "START"}))
	
	# Validate program
	var validation = program.validate()
	assert_bool(validation["is_valid"]).is_true()
	
	print("[TEST] ✓ User can create a valid loop with LABEL and GOTO")


## TEST 3: Translation service translates program correctly
func test_translation_service_translates_program() -> void:
	var program = ProgramScript.new("Test Program")
	program.add_instruction(InstructionScript.new("MOVE", 2))
	program.add_instruction(InstructionScript.new("ATTACK", 3))
	
	# Translate the program
	var result = translation_service.translate_program(program)
	
	# Should succeed
	assert_bool(result["success"]).is_true()
	assert_int(result["instructions"].size()).is_equal(2)
	
	# Check that instructions have execute callbacks
	assert_object(result["instructions"][0]["execute"]).is_not_null()
	
	print("[TEST] ✓ Translation service successfully translates programs")


## TEST 4: Android can load and execute a program
func test_android_loads_and_executes_program() -> void:
	test_android = AndroidEntityScript.new()
	test_android.android_name = "Test Android"
	add_child(test_android)
	
	# Wait for android to initialize
	await wait_frames(2)
	
	# Create a simple program
	var program = ProgramScript.new("Android Program")
	program.add_instruction(InstructionScript.new("MOVE", 1))
	
	# Android should be able to load the program
	var load_success = test_android.load_program(program)
	assert_bool(load_success).is_true()
	
	# Android's AI core should have the program
	assert_object(test_android.ai_core.program).is_not_null()
	
	print("[TEST] ✓ Android can load a program")


## TEST 5: Program validation catches errors
func test_program_validation_catches_invalid_goto() -> void:
	var program = ProgramScript.new("Invalid Program")
	
	# Add GOTO that references non-existent label
	program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "NONEXISTENT"}))
	
	var validation = program.validate()
	assert_bool(validation["is_valid"]).is_false()
	assert_array(validation["errors"]).is_not_empty()
	
	print("[TEST] ✓ Program validation catches invalid GOTO references")


## TEST 6: Program duplication creates independent copy
func test_program_duplication_is_independent() -> void:
	var original = ProgramScript.new("Original")
	original.add_instruction(InstructionScript.new("MOVE", 2))
	
	var copy = original.duplicate_program()
	
	# Modify copy
	copy.program_name = "Copy"
	copy.add_instruction(InstructionScript.new("ATTACK", 3))
	
	# Original should be unchanged
	assert_str(original.program_name).is_equal("Original")
	assert_int(original.instructions.size()).is_equal(1)
	assert_int(copy.instructions.size()).is_equal(2)
	
	print("[TEST] ✓ Program duplication creates independent copy")


## TEST 7: Instruction types are correctly identified
func test_instruction_types_are_valid() -> void:
	var move = InstructionScript.new("MOVE", 2)
	var attack = InstructionScript.new("ATTACK", 3)
	var goto_instr = InstructionScript.new("GOTO", 1, {"label": "START"})
	
	assert_str(move.type).is_equal("MOVE")
	assert_str(attack.type).is_equal("ATTACK")
	assert_str(goto_instr.type).is_equal("GOTO")
	assert_str(goto_instr.parameters.get("label")).is_equal("START")
	
	print("[TEST] ✓ Instruction types are correctly identified")


## TEST 8: CPU cost calculation
func test_program_calculates_cpu_cost() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("MOVE", 2))
	program.add_instruction(InstructionScript.new("ATTACK", 3))
	program.add_instruction(InstructionScript.new("GOTO", 1))
	
	var total_cost = program.get_total_cpu_cost()
	assert_int(total_cost).is_equal(6)  # 2 + 3 + 1
	
	print("[TEST] ✓ Program calculates total CPU cost correctly")


## TEST 9: Translation builds correct label map
func test_translation_builds_label_map() -> void:
	var program = ProgramScript.new()
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	program.add_instruction(InstructionScript.new("MOVE", 2))
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "LOOP"}))
	program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "START"}))
	
	var result = translation_service.translate_program(program)
	
	# Label map should contain both labels
	assert_int(result["label_map"]["START"]).is_equal(0)
	assert_int(result["label_map"]["LOOP"]).is_equal(2)
	
	print("[TEST] ✓ Translation builds correct label map")


## TEST 10: End-to-end workflow simulation
func test_complete_user_workflow() -> void:
	print("\n[TEST] === COMPLETE USER WORKFLOW ===")
	
	# 1. User creates program
	var program = ProgramScript.new("Combat Bot")
	print("[TEST] Step 1: Created program 'Combat Bot'")
	
	# 2. User adds instructions
	program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "MAIN_LOOP"}))
	program.add_instruction(InstructionScript.new("MOVE", 2, {"direction": "forward", "distance": 10.0}))
	program.add_instruction(InstructionScript.new("ATTACK", 3))
	program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "MAIN_LOOP"}))
	print("[TEST] Step 2: Added 4 instructions (LABEL, MOVE, ATTACK, GOTO)")
	
	# 3. User validates program
	var validation = program.validate()
	assert_bool(validation["is_valid"]).is_true()
	print("[TEST] Step 3: Program validation passed ✓")
	
	# 4. Program is translated
	var translated = translation_service.translate_program(program)
	assert_bool(translated["success"]).is_true()
	print("[TEST] Step 4: Program translation successful ✓")
	
	# 5. Android loads program
	test_android = AndroidEntityScript.new()
	add_child(test_android)
	await wait_frames(2)
	
	var loaded = test_android.load_program(program)
	assert_bool(loaded).is_true()
	print("[TEST] Step 5: Android loaded program ✓")
	
	# 6. Execution can start
	test_android.start_ai()
	assert_bool(test_android.ai_core.is_executing).is_true()
	print("[TEST] Step 6: AI execution started ✓")
	
	print("[TEST] === ALL WORKFLOW STEPS PASSED ===\n")
