## Represents a single Instruction in an AI Program.
## The smallest unit of logic that can be executed by an AI Core.
## Examples: MOVE_FORWARD, READ_SENSOR, GOTO, CONDITION_CHECK.
class_name Instruction
extends Resource


## Type of instruction (e.g., "MOVE", "ATTACK", "GOTO", "CONDITION").
@export var type: String = ""

## CPU cost to execute this instruction.
## Affects whether it fits in the Android's CPU capacity.
@export var cpu_cost: int = 1

## Parameters for this instruction (e.g., {"direction": "forward"}).
@export var parameters: Dictionary = {}

## Unique ID for this instruction instance (for debugging/tracking).
@export var instruction_id: String = ""


func _init(
	p_type: String = "",
	p_cpu_cost: int = 1,
	p_parameters: Dictionary = {},
	p_instruction_id: String = ""
) -> void:
	type = p_type
	cpu_cost = p_cpu_cost
	parameters = p_parameters.duplicate(true)
	instruction_id = p_instruction_id if p_instruction_id else _generate_id()


## Validates whether this instruction is properly configured.
func is_valid() -> bool:
	if type.is_empty():
		return false
	# Note: cpu_cost can be 0 for labels and no-cost operations
	if cpu_cost < 0:
		return false
	return true


## Returns a human-readable string representation of this instruction.
func get_description() -> String:
	var param_str: String = ""
	if not parameters.is_empty():
		param_str = " " + str(parameters)
	return "[%s] %s (CPU: %d)%s" % [instruction_id, type, cpu_cost, param_str]


## Generates a unique ID for this instruction.
func _generate_id() -> String:
	return "%s_%d" % [type, Time.get_ticks_usec()]


## Creates a deep copy of this instruction.
func duplicate_instruction():
	var copy = get_script().new(type, cpu_cost, parameters, instruction_id)
	return copy
