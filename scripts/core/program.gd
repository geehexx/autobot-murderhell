## Represents an AI Program - a sequence of Instructions.
## This is the aggregate root for the Programming Context.
## The player creates this via the Block Editor.
class_name Program
extends Resource


## The name of this program (for display purposes).
@export var program_name: String = "Untitled Program"

## Ordered list of Instructions that make up this program.
@export var instructions: Array[Instruction] = []

## Variables defined in this program (name -> initial value).
## In the MVP, this might be simple integers or references.
@export var variables: Dictionary = {}

## Memory cells allocated for this program (index -> value).
## Analogous to floor tiles in Human Resource Machine.
@export var memory_cells: Array = []

## Maximum number of memory cells this program can use.
@export var max_memory_cells: int = 4


func _init(
	p_name: String = "Untitled Program",
	p_max_memory: int = 4
) -> void:
	program_name = p_name
	max_memory_cells = p_max_memory
	memory_cells.resize(max_memory_cells)
	memory_cells.fill(0)


## Adds an instruction to the end of the program.
func add_instruction(instruction: Instruction) -> void:
	if instruction and instruction.is_valid():
		instructions.append(instruction)


## Inserts an instruction at a specific index.
func insert_instruction(instruction: Instruction, index: int) -> void:
	if instruction and instruction.is_valid():
		if index >= 0 and index <= instructions.size():
			instructions.insert(index, instruction)


## Removes an instruction at a specific index.
func remove_instruction(index: int) -> bool:
	if index >= 0 and index < instructions.size():
		instructions.remove_at(index)
		return true
	return false


## Gets the total CPU cost of this program.
func get_total_cpu_cost() -> int:
	var total: int = 0
	for instruction in instructions:
		total += instruction.cpu_cost
	return total


## Validates the entire program for basic errors.
## Returns a tuple: [is_valid: bool, errors: Array[String]]
func validate() -> Dictionary:
	var errors: Array[String] = []
	
	if instructions.is_empty():
		errors.append("Program has no instructions")
	
	for i in instructions.size():
		var instruction: Instruction = instructions[i]
		if not instruction.is_valid():
			errors.append("Instruction at index %d is invalid" % i)
	
	# Check for disconnected GOTO targets (basic validation)
	for instruction in instructions:
		if instruction.type == "GOTO":
			var target_label: String = instruction.parameters.get("label", "")
			if not _has_label(target_label):
				errors.append("GOTO references non-existent label: %s" % target_label)
	
	return {
		"is_valid": errors.is_empty(),
		"errors": errors
	}


## Checks if a label exists in the program.
func _has_label(label: String) -> bool:
	for instruction in instructions:
		if instruction.type == "LABEL" and instruction.parameters.get("name", "") == label:
			return true
	return false


## Returns a string representation of the entire program.
func to_string() -> String:
	var lines: PackedStringArray = []
	lines.append("=== %s ===" % program_name)
	lines.append("CPU Cost: %d" % get_total_cpu_cost())
	lines.append("Memory Cells: %d" % max_memory_cells)
	lines.append("Instructions:")
	for i in instructions.size():
		lines.append("  %d: %s" % [i, instructions[i].to_string()])
	return "\n".join(lines)


## Creates a deep copy of this program.
func duplicate_program() -> Program:
	var copy: Program = Program.new(program_name, max_memory_cells)
	for instruction in instructions:
		copy.instructions.append(instruction.duplicate_instruction())
	copy.variables = variables.duplicate(true)
	copy.memory_cells = memory_cells.duplicate(true)
	return copy
