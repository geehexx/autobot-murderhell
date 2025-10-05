## Represents an AI Program - a sequence of low-level Instructions.
## Updated per ADR-003 to include CPU budgeting and blackboard defaults.
class_name Program
extends Resource


## The name of this program (for display purposes).
@export var program_name: String = "Untitled Program"

## Ordered list of Instructions that make up this program.
@export var instructions: Array = []

## Initial blackboard values (variable -> value) restored on load.
@export var blackboard_defaults: Dictionary = {}

## Maximum CPU cycles the AI Core may consume per frame.
@export var cpu_budget_per_tick: int = 100


func _init(
	p_name: String = "Untitled Program",
	p_cpu_budget_per_tick: int = 100
) -> void:
	program_name = p_name
	cpu_budget_per_tick = p_cpu_budget_per_tick


## Adds an instruction to the end of the program.
func add_instruction(instruction) -> void:
	if instruction and instruction.is_valid():
		instructions.append(instruction)


## Inserts an instruction at a specific index.
func insert_instruction(instruction, index: int) -> void:
	if instruction and instruction.is_valid():
		if index >= 0 and index <= instructions.size():
			instructions.insert(index, instruction)


## Removes an instruction at a given index.
func remove_instruction(index: int) -> bool:
	if index >= 0 and index < instructions.size():
		instructions.remove_at(index)
		return true
	return false
## Gets the total CPU cost of this program.
func get_total_cpu_cost() -> int:
	var total: int = 0
	for instruction in instructions:
		if instruction:
			total += instruction.cpu_cost
	return total


## Validates the entire program for basic errors.
## Returns a dictionary: { "is_valid": bool, "errors": Array }
func validate() -> Dictionary:
	var errors: Array = []

	if instructions.is_empty():
		errors.append("Program has no instructions")
	else:
		var label_map := _collect_labels(errors)
		for i in instructions.size():
			var instruction = instructions[i]
			if not instruction:
				errors.append("Instruction at index %d is null" % i)
				continue
			if not instruction.is_valid():
				errors.append("Instruction at index %d has invalid definition" % i)
				continue
			errors += _validate_instruction_parameters(instruction, i)
			if instruction.type == "JUMP_IF":
				var target_label: String = instruction.parameters.get("target_label", "")
				if target_label.is_empty():
					errors.append("JUMP_IF at index %d missing target_label" % i)
				elif not label_map.has(target_label):
					errors.append("JUMP_IF at index %d references unknown label '%s'" % [i, target_label])
			if instruction.type == "LABEL":
				var label_name: String = instruction.parameters.get("name", "")
				if label_name.is_empty():
					errors.append("LABEL at index %d missing name" % i)

	return {
		"is_valid": errors.is_empty(),
		"errors": errors
	}


## Checks if a label exists in the program.
func _collect_labels(errors: Array) -> Dictionary:
	var label_map: Dictionary = {}
	for i in instructions.size():
		var instruction = instructions[i]
		if not instruction or instruction.type != "LABEL":
			continue
		var label_name: String = instruction.parameters.get("name", "")
		if label_name.is_empty():
			errors.append("LABEL at index %d missing name" % i)
		elif label_map.has(label_name):
			errors.append("Duplicate LABEL name '%s' at index %d" % [label_name, i])
		else:
			label_map[label_name] = i
	return label_map


func _validate_instruction_parameters(instruction, index: int) -> Array:
	var errors: Array = []
	var definition: Dictionary = instruction.get_definition()
	if definition.is_empty():
		errors.append("Instruction at index %d has unknown type '%s'" % [index, instruction.type])
		return errors

	var required_params: Array = definition.get("required_params", [])
	for param_name in required_params:
		if not instruction.parameters.has(param_name):
			errors.append("Instruction '%s' at index %d missing required parameter '%s'" % [instruction.type, index, param_name])

	return errors


## Returns a string representation of the entire program.
func get_description() -> String:
	var lines: PackedStringArray = []
	lines.append("=== %s ===" % program_name)
	lines.append("CPU Cost: %d" % get_total_cpu_cost())
	lines.append("CPU Budget/Tick: %d" % cpu_budget_per_tick)
	lines.append("Instructions:")
	for i in instructions.size():
		var instruction = instructions[i]
		var description: String = instruction.get_description() if instruction else "<null>"
		lines.append("  %d: %s" % [i, description])
	return "\n".join(lines)


## Creates a deep copy of this program.
func duplicate_program():
	var copy = get_script().new(program_name, cpu_budget_per_tick)
	for instruction in instructions:
		if instruction:
			copy.instructions.append(instruction.duplicate_instruction())
	copy.blackboard_defaults = blackboard_defaults.duplicate(true)
	return copy
