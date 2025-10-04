## AI Core Component for Androids.
## Executes a Program and manages execution state.
## This is the "brain" of an Android.
class_name AICoreComponent
extends Node


## The Program this AI Core is currently executing.
var program: Program = null

## Current instruction pointer (index into program.instructions).
var instruction_pointer: int = 0

## CPU capacity of this AI Core (limits program complexity).
@export var cpu_capacity: int = 10

## Whether the AI is currently executing.
var is_executing: bool = false

## Whether execution is paused (for debugging).
var is_paused: bool = false

## Current execution state (variables, memory).
var execution_state: Dictionary = {}


func _ready() -> void:
	# Connect to debug events
	EventBus.debug_pause_toggled.connect(_on_debug_pause_toggled)
	EventBus.debug_step_requested.connect(_on_debug_step_requested)


## Loads a Program into this AI Core.
## Validates that the program fits within CPU capacity.
func load_program(p_program: Program) -> bool:
	if not p_program:
		push_error("[AICoreComponent] Cannot load null program")
		return false
	
	var validation: Dictionary = p_program.validate()
	if not validation["is_valid"]:
		push_error("[AICoreComponent] Program validation failed: %s" % str(validation["errors"]))
		return false
	
	var cpu_cost: int = p_program.get_total_cpu_cost()
	if cpu_cost > cpu_capacity:
		push_error("[AICoreComponent] Program CPU cost (%d) exceeds capacity (%d)" % [cpu_cost, cpu_capacity])
		return false
	
	program = p_program
	instruction_pointer = 0
	execution_state = {
		"memory": program.memory_cells.duplicate(),
		"variables": program.variables.duplicate()
	}
	
	print("[AICoreComponent] Program '%s' loaded successfully (CPU: %d/%d)" % [
		program.program_name,
		cpu_cost,
		cpu_capacity
	])
	
	return true


## Starts program execution.
func start_execution() -> void:
	if not program:
		push_error("[AICoreComponent] No program loaded")
		return
	
	is_executing = true
	instruction_pointer = 0
	print("[AICoreComponent] Execution started")


## Stops program execution.
func stop_execution() -> void:
	is_executing = false
	print("[AICoreComponent] Execution stopped")


## Executes a single instruction (called each simulation tick).
## Returns true if execution should continue, false if program ended.
func execute_step() -> bool:
	if not is_executing or is_paused or not program:
		return false
	
	if instruction_pointer >= program.instructions.size():
		# Program ended
		stop_execution()
		return false
	
	var instruction: Instruction = program.instructions[instruction_pointer]
	
	# Emit debug event
	EventBus.instruction_executed.emit(instruction_pointer, execution_state)
	
	# Execute the instruction (placeholder - will be expanded in AI Translation Service)
	_execute_instruction(instruction)
	
	# Move to next instruction (or jump if GOTO)
	instruction_pointer += 1
	
	return true


## Executes a single instruction (placeholder implementation).
func _execute_instruction(instruction: Instruction) -> void:
	match instruction.type:
		"MOVE":
			print("  [AI] Execute: MOVE %s" % str(instruction.parameters))
		"ATTACK":
			print("  [AI] Execute: ATTACK")
		"GOTO":
			var label: String = instruction.parameters.get("label", "")
			_jump_to_label(label)
		"LABEL":
			# Labels are markers, no execution needed
			pass
		_:
			print("  [AI] Unknown instruction: %s" % instruction.type)


## Jumps instruction pointer to a labeled position.
func _jump_to_label(label: String) -> void:
	for i in program.instructions.size():
		var instr: Instruction = program.instructions[i]
		if instr.type == "LABEL" and instr.parameters.get("name", "") == label:
			instruction_pointer = i
			return
	
	push_error("[AICoreComponent] GOTO failed: label '%s' not found" % label)


## Callback for debug pause toggle.
func _on_debug_pause_toggled(paused: bool) -> void:
	is_paused = paused
	print("[AICoreComponent] Execution %s" % ("paused" if paused else "resumed"))


## Callback for debug step request.
func _on_debug_step_requested() -> void:
	if is_paused and is_executing:
		execute_step()
