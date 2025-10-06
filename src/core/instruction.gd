## Represents a single Instruction in an AI Program.
## Updated to align with ADR-003 low-level instruction architecture.
class_name Instruction
extends Resource


## Instruction catalogue defining metadata for all supported instructions.
const INSTRUCTION_DEFINITIONS := {
	"SET_VARIABLE": {
		"category": "data_io",
		"cpu_cost": 1,
		"required_params": ["target"],
		"optional_params": ["value", "source"]
	},
	"MATH_OP": {
		"category": "data_io",
		"cpu_cost": 1,
		"required_params": ["operation", "lhs", "rhs", "store_in"],
		"optional_params": []
	},
	"VECTOR_OP": {
		"category": "data_io",
		"cpu_cost": 1,
		"required_params": ["operation", "vector_a", "vector_b", "store_in"],
		"optional_params": ["scalar"]
	},
	"GET_SENSOR_DATA": {
		"category": "data_io",
		"cpu_cost": 1,
		"required_params": ["sensor", "store_in"],
		"optional_params": ["target"]
	},
	"DEBUG_LOG": {
		"category": "data_io",
		"cpu_cost": 0,
		"required_params": ["message"],
		"optional_params": ["values"]
	},
	"LABEL": {
		"category": "control_flow",
		"cpu_cost": 0,
		"required_params": ["name"],
		"optional_params": []
	},
	"JUMP_IF": {
		"category": "control_flow",
		"cpu_cost": 1,
		"required_params": ["condition", "target_label"],
		"optional_params": ["negate"]
	},
	"SET_TARGET_VELOCITY": {
		"category": "hardware",
		"cpu_cost": 2,
		"required_params": ["velocity"],
		"optional_params": ["blend"]
	},
	"SET_ROTATION_TARGET": {
		"category": "hardware",
		"cpu_cost": 2,
		"required_params": ["rotation_deg"],
		"optional_params": []
	},
	"FIRE_WEAPON": {
		"category": "hardware",
		"cpu_cost": 2,
		"required_params": [],
		"optional_params": ["weapon_id"]
	},
	# Legacy instructions maintained for backward compatibility with pre-ADR programs.
	"MOVE": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": [],
		"optional_params": ["direction", "distance"]
	},
	"ATTACK": {
		"category": "legacy",
		"cpu_cost": 2,
		"required_params": [],
		"optional_params": []
	},
	"GOTO": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": ["label"],
		"optional_params": []
	},
	"CONDITION": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": ["condition_type"],
		"optional_params": ["jump_if_true", "jump_if_false"]
	},
	"READ_SENSOR": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": ["sensor_type", "store_in"],
		"optional_params": []
	},
	"WRITE_MEMORY": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": ["cell_index", "value_source"],
		"optional_params": []
	},
	"READ_MEMORY": {
		"category": "legacy",
		"cpu_cost": 1,
		"required_params": ["cell_index", "store_in"],
		"optional_params": []
	}
}


## Type of instruction (e.g., "SET_VARIABLE", "JUMP_IF").
@export var type: String = ""

## CPU cost to execute this instruction.
## Defaults to the catalogue value when not provided.
@export var cpu_cost: int = -1

## Parameters for this instruction.
@export var parameters: Dictionary = {}

## Unique ID for this instruction instance (for debugging/tracking).
@export var instruction_id: String = ""


func _init(
	p_type: String = "",
	p_cpu_cost: int = -1,
	p_parameters: Dictionary = {},
	p_instruction_id: String = ""
) -> void:
	type = p_type
	cpu_cost = _resolve_cpu_cost(p_type, p_cpu_cost)
	parameters = p_parameters.duplicate(true)
	instruction_id = p_instruction_id if p_instruction_id else _generate_id()


## Returns metadata for this instruction type.
func get_definition() -> Dictionary:
	return INSTRUCTION_DEFINITIONS.get(type, {})


## Validates whether this instruction is properly configured.
func is_valid() -> bool:
	if type.is_empty():
		return false
	if not INSTRUCTION_DEFINITIONS.has(type):
		return false
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


## Helper to resolve default CPU cost for a type.
func _resolve_cpu_cost(p_type: String, requested_cost: int) -> int:
	if requested_cost >= 0:
		return requested_cost
	var definition: Dictionary = INSTRUCTION_DEFINITIONS.get(p_type, null)
	if definition and definition.has("cpu_cost"):
		return definition["cpu_cost"]
	return 0
