## Block Editor UI - visual programming interface.
## Mobile-first design following ADR-002.
## This is the primary interface for creating AI Programs.
extends Control

# Preload required classes
const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")
const PlayerProfileScript = preload("res://src/progression/player_profile.gd")

## Reference to current Program.
var current_program = null

## Reference to player profile.
var player_profile = null

## References to UI elements.
@onready var block_list: VBoxContainer = %BlockList
@onready var program_list: VBoxContainer = %ProgramList
@onready var cpu_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/CPULabel
@onready var save_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/SaveButton
@onready var deploy_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/DeployButton

## Packed scene for block UI elements.
var block_ui_scene: PackedScene = preload("res://src/ui/block_ui.tscn")


func _ready() -> void:
	# Connect button signals
	save_button.pressed.connect(_on_save_button_pressed)
	deploy_button.pressed.connect(_on_deploy_button_pressed)
	
	# Connect to EventBus
	EventBus.program_edited.connect(_on_program_edited)
	
	# Initialize with a new program
	create_new_program()
	
	print("[BlockEditor] Initialized")


## Creates a new empty program.
func create_new_program() -> void:
	current_program = ProgramScript.new("New Program")
	_refresh_ui()


## Loads a program into the editor.
func load_program(program) -> void:
	if not program:
		push_error("[BlockEditor] Cannot load null program")
		return
	
	current_program = program.duplicate_program()
	_refresh_ui()
	print("[BlockEditor] Loaded program: %s" % program.program_name)


## Sets the player profile to determine available blocks.
func set_player_profile(profile) -> void:
	player_profile = profile
	_populate_block_palette()


## Populates the block palette with available blocks.
func _populate_block_palette() -> void:
	# Clear existing blocks
	for child in block_list.get_children():
		child.queue_free()
	
	# Get unlocked blocks
	var unlocked_blocks: Array = []
	if player_profile:
		unlocked_blocks = player_profile.unlocked_blocks
	else:
		# Default blocks for testing
		unlocked_blocks = [
			"SET_VARIABLE",
			"MATH_OP",
			"VECTOR_OP",
			"GET_SENSOR_DATA",
			"DEBUG_LOG",
			"SET_TARGET_VELOCITY",
			"SET_ROTATION_TARGET",
			"FIRE_WEAPON",
			"LABEL",
			"JUMP_IF"
		]
	
	# Create UI elements for each block
	for block_type in unlocked_blocks:
		var block_button: Button = Button.new()
		block_button.text = block_type
		block_button.custom_minimum_size = Vector2(0, 48)  # Mobile-friendly touch target
		block_button.pressed.connect(_on_add_block_pressed.bind(block_type))
		block_list.add_child(block_button)


## Refreshes the entire UI to match current program state.
func _refresh_ui() -> void:
	_update_program_display()
	_update_cpu_display()


## Updates the program workspace display.
func _update_program_display() -> void:
	# Clear existing display
	for child in program_list.get_children():
		child.queue_free()
	
	if not current_program:
		return
	
	# Display each instruction
	for i in current_program.instructions.size():
		var instruction = current_program.instructions[i]
		var instruction_ui: Control = _create_instruction_ui(instruction, i)
		program_list.add_child(instruction_ui)
	
	# Add placeholder if empty
	if current_program.instructions.is_empty():
		var label: Label = Label.new()
		label.text = "Drag blocks here to create your program"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		program_list.add_child(label)


## Creates a UI element for an instruction.
func _create_instruction_ui(instruction, index: int) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	
	# Top row: instruction info and controls
	var panel: PanelContainer = PanelContainer.new()
	var hbox: HBoxContainer = HBoxContainer.new()
	panel.add_child(hbox)
	vbox.add_child(panel)
	
	# Index label
	var index_label: Label = Label.new()
	index_label.text = "%d:" % index
	index_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(index_label)
	
	# Instruction label
	var instr_label: Label = Label.new()
	instr_label.text = instruction.type
	instr_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(instr_label)
	
	# CPU cost label
	var cpu_label_local: Label = Label.new()
	cpu_label_local.text = "CPU: %d" % instruction.cpu_cost
	hbox.add_child(cpu_label_local)
	
	# Delete button
	var delete_button: Button = Button.new()
	delete_button.text = "X"
	delete_button.custom_minimum_size = Vector2(48, 48)
	delete_button.pressed.connect(_on_delete_instruction_pressed.bind(index))
	hbox.add_child(delete_button)
	
	# Add parameter editors based on instruction type
	var param_ui = _create_parameter_ui(instruction, index)
	if param_ui:
		vbox.add_child(param_ui)
	
	return vbox


## Creates parameter editing UI for an instruction
func _create_parameter_ui(instruction, index: int):
	match instruction.type:
		"SET_VARIABLE":
			return _create_set_variable_params(instruction, index)
		"LABEL":
			return _create_label_params(instruction, index)
		"SET_TARGET_VELOCITY":
			return _create_set_target_velocity_params(instruction, index)
		"JUMP_IF":
			return _create_jump_if_params(instruction, index)
		"DEBUG_LOG":
			return _create_debug_log_params(instruction, index)
		_:
			return null


## Creates MOVE parameter UI
## Creates SET_VARIABLE parameter UI
func _create_set_variable_params(instruction, index: int) -> Control:
	var vbox = VBoxContainer.new()
	
	var target_hbox = HBoxContainer.new()
	var target_label = Label.new()
	target_label.text = "Target:"
	target_hbox.add_child(target_label)

	var target_edit = LineEdit.new()
	target_edit.text = instruction.parameters.get("target", "")
	target_edit.custom_minimum_size = Vector2(150, 0)
	target_edit.text_changed.connect(func(new_text):
		instruction.parameters["target"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	target_hbox.add_child(target_edit)
	vbox.add_child(target_hbox)

	var value_hbox = HBoxContainer.new()
	var value_label = Label.new()
	value_label.text = "Value:"
	value_hbox.add_child(value_label)

	var value_edit = LineEdit.new()
	value_edit.text = str(instruction.parameters.get("value", ""))
	value_edit.custom_minimum_size = Vector2(150, 0)
	value_edit.text_changed.connect(func(new_text):
		instruction.parameters["value"] = new_text
		instruction.parameters.erase("source")
		EventBus.program_edited.emit(current_program)
	)
	value_hbox.add_child(value_edit)
	vbox.add_child(value_hbox)

	return vbox


## Creates LABEL parameter UI
func _create_label_params(instruction, index: int) -> Control:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "Label name:"
	hbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.text = instruction.parameters.get("name", "START")
	line_edit.custom_minimum_size = Vector2(150, 0)
	line_edit.text_changed.connect(func(new_text):
		instruction.parameters["name"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	hbox.add_child(line_edit)
	
	return hbox


## Creates SET_TARGET_VELOCITY parameter UI
func _create_set_target_velocity_params(instruction, index: int) -> Control:
	var vbox = VBoxContainer.new()
	var velocity = instruction.parameters.get("velocity", Vector2.ZERO)

	var x_hbox = HBoxContainer.new()
	var x_label = Label.new()
	x_label.text = "Velocity X:"
	x_hbox.add_child(x_label)

	var x_spin = SpinBox.new()
	x_spin.min_value = -1000.0
	x_spin.max_value = 1000.0
	x_spin.step = 5.0
	x_spin.value = velocity.x
	x_spin.value_changed.connect(func(value):
		instruction.parameters["velocity"] = Vector2(value, instruction.parameters.get("velocity", Vector2.ZERO).y)
		EventBus.program_edited.emit(current_program)
	)
	x_hbox.add_child(x_spin)
	vbox.add_child(x_hbox)

	var y_hbox = HBoxContainer.new()
	var y_label = Label.new()
	y_label.text = "Velocity Y:"
	y_hbox.add_child(y_label)

	var y_spin = SpinBox.new()
	y_spin.min_value = -1000.0
	y_spin.max_value = 1000.0
	y_spin.step = 5.0
	y_spin.value = velocity.y
	y_spin.value_changed.connect(func(value):
		instruction.parameters["velocity"] = Vector2(instruction.parameters.get("velocity", Vector2.ZERO).x, value)
		EventBus.program_edited.emit(current_program)
	)
	y_hbox.add_child(y_spin)
	vbox.add_child(y_hbox)

	var blend_hbox = HBoxContainer.new()
	var blend_label = Label.new()
	blend_label.text = "Blend:"
	blend_hbox.add_child(blend_label)

	var blend_spin = SpinBox.new()
	blend_spin.min_value = 0.0
	blend_spin.max_value = 1.0
	blend_spin.step = 0.1
	blend_spin.value = float(instruction.parameters.get("blend", 1.0))
	blend_spin.value_changed.connect(func(value):
		instruction.parameters["blend"] = value
		EventBus.program_edited.emit(current_program)
	)
	blend_hbox.add_child(blend_spin)
	vbox.add_child(blend_hbox)

	return vbox


## Creates JUMP_IF parameter UI
func _create_jump_if_params(instruction, index: int) -> Control:
	var vbox = VBoxContainer.new()

	var target_hbox = HBoxContainer.new()
	var target_label = Label.new()
	target_label.text = "Target Label:"
	target_hbox.add_child(target_label)

	var target_edit = LineEdit.new()
	target_edit.text = instruction.parameters.get("target_label", "")
	target_edit.custom_minimum_size = Vector2(150, 0)
	target_edit.text_changed.connect(func(new_text):
		instruction.parameters["target_label"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	target_hbox.add_child(target_edit)
	vbox.add_child(target_hbox)

	var else_hbox = HBoxContainer.new()
	var else_label = Label.new()
	else_label.text = "Else Label:"
	else_hbox.add_child(else_label)

	var else_edit = LineEdit.new()
	else_edit.text = instruction.parameters.get("else_label", "")
	else_edit.custom_minimum_size = Vector2(150, 0)
	else_edit.text_changed.connect(func(new_text):
		if new_text.is_empty():
			instruction.parameters.erase("else_label")
		else:
			instruction.parameters["else_label"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	else_hbox.add_child(else_edit)
	vbox.add_child(else_hbox)

	return vbox


## Creates DEBUG_LOG parameter UI
func _create_debug_log_params(instruction, index: int) -> Control:
	var hbox = HBoxContainer.new()

	var message_label = Label.new()
	message_label.text = "Message:"
	hbox.add_child(message_label)

	var message_edit = LineEdit.new()
	message_edit.text = instruction.parameters.get("message", "")
	message_edit.custom_minimum_size = Vector2(200, 0)
	message_edit.text_changed.connect(func(new_text):
		instruction.parameters["message"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	hbox.add_child(message_edit)

	return hbox


## Updates the CPU cost display.
func _update_cpu_display() -> void:
	if not current_program:
		cpu_label.text = "CPU: 0/10"
		return
	
	var total_cost: int = current_program.get_total_cpu_cost()
	var capacity: int = 10  # TODO: Get from player's Android CPU
	cpu_label.text = "CPU: %d/%d" % [total_cost, capacity]
	
	# Color code based on capacity
	if total_cost > capacity:
		cpu_label.modulate = Color.RED
	elif total_cost == capacity:
		cpu_label.modulate = Color.YELLOW
	else:
		cpu_label.modulate = Color.WHITE


## Callback when add block button is pressed.
func _on_add_block_pressed(block_type: String) -> void:
	if not current_program:
		return
	
	# Create instruction based on block type
	var instruction = _create_instruction_from_type(block_type)
	current_program.add_instruction(instruction)
	
	_refresh_ui()
	EventBus.program_edited.emit(current_program)
	


## Creates an instruction from a block type.
func _create_instruction_from_type(block_type: String):
	match block_type:
		"SET_VARIABLE":
			return InstructionScript.new("SET_VARIABLE", -1, {"target": "var_name", "value": 0})
		"MATH_OP":
			return InstructionScript.new("MATH_OP", 1, {
				"operation": "add",
				"lhs": 0,
				"rhs": 0,
				"store_in": "result"
			})
		"VECTOR_OP":
			return InstructionScript.new("VECTOR_OP", 1, {
				"operation": "add",
				"vector_a": Vector2.ZERO,
				"vector_b": Vector2.ZERO,
				"store_in": "vector_result"
			})
		"GET_SENSOR_DATA":
			return InstructionScript.new("GET_SENSOR_DATA", 1, {
				"sensor": "SELF_POSITION",
				"store_in": "position"
			})
		"DEBUG_LOG":
			return InstructionScript.new("DEBUG_LOG", 0, {"message": "Log message"})
		"SET_TARGET_VELOCITY":
			return InstructionScript.new("SET_TARGET_VELOCITY", 2, {
				"velocity": Vector2.ZERO,
				"blend": 1.0
			})
		"SET_ROTATION_TARGET":
			return InstructionScript.new("SET_ROTATION_TARGET", 2, {"rotation_deg": 0.0})
		"FIRE_WEAPON":
			return InstructionScript.new("FIRE_WEAPON", 2, {})
		"LABEL":
			return InstructionScript.new("LABEL", 0, {"name": "START"})
		"JUMP_IF":
			return InstructionScript.new("JUMP_IF", 1, {
				"condition": {"operator": "is_true", "lhs": true},
				"target_label": "START"
			})
		_:
			return InstructionScript.new(block_type, 1, {})


## Callback when delete instruction button is pressed.
func _on_delete_instruction_pressed(index: int) -> void:
	if not current_program:
		return
	
	current_program.remove_instruction(index)
	_refresh_ui()
	EventBus.program_edited.emit(current_program)
	
	print("[BlockEditor] Removed instruction at index %d" % index)


## Callback when save button is pressed.
func _on_save_button_pressed() -> void:
	if not current_program:
		return
	
	print("[BlockEditor] Program saved: %s" % current_program.program_name)
	# TODO: Actually save to storage or player profile


## Callback when deploy button is pressed.
func _on_deploy_button_pressed() -> void:
	if not current_program:
		return
	
	# Validate program
	var validation: Dictionary = current_program.validate()
	if not validation["is_valid"]:
		print("[BlockEditor] Cannot deploy - program invalid: %s" % str(validation["errors"]))
		# TODO: Show error dialog
		return
	
	print("[BlockEditor] Deploying program...")
	EventBus.translate_program_requested.emit(current_program)
	EventBus.run_started.emit("level_1", current_program)


## Callback when program is edited externally.
func _on_program_edited(program) -> void:
	if program == current_program:
		_refresh_ui()
