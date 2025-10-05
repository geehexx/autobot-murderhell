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
		unlocked_blocks = ["MOVE", "ATTACK", "GOTO", "LABEL", "CONDITION"]
	
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
		"MOVE":
			return _create_move_params(instruction, index)
		"GOTO":
			return _create_goto_params(instruction, index)
		"LABEL":
			return _create_label_params(instruction, index)
		"CONDITION":
			return _create_condition_params(instruction, index)
		_:
			return null


## Creates MOVE parameter UI
func _create_move_params(instruction, index: int) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	# Direction dropdown
	var direction_label = Label.new()
	direction_label.text = "Direction:"
	hbox.add_child(direction_label)
	
	var direction_option = OptionButton.new()
	direction_option.add_item("forward", 0)
	direction_option.add_item("backward", 1)
	direction_option.add_item("left", 2)
	direction_option.add_item("right", 3)
	
	var current_dir = instruction.parameters.get("direction", "forward")
	match current_dir:
		"forward": direction_option.selected = 0
		"backward": direction_option.selected = 1
		"left": direction_option.selected = 2
		"right": direction_option.selected = 3
	
	direction_option.item_selected.connect(func(idx):
		var dirs = ["forward", "backward", "left", "right"]
		instruction.parameters["direction"] = dirs[idx]
		EventBus.program_edited.emit(current_program)
	)
	hbox.add_child(direction_option)
	
	# Distance input
	var distance_label = Label.new()
	distance_label.text = "Distance:"
	hbox.add_child(distance_label)
	
	var distance_spin = SpinBox.new()
	distance_spin.min_value = 1.0
	distance_spin.max_value = 500.0
	distance_spin.step = 10.0
	distance_spin.value = instruction.parameters.get("distance", 50.0)
	distance_spin.value_changed.connect(func(value):
		instruction.parameters["distance"] = value
		EventBus.program_edited.emit(current_program)
	)
	hbox.add_child(distance_spin)
	
	return hbox


## Creates GOTO parameter UI
func _create_goto_params(instruction, index: int) -> Control:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "Jump to label:"
	hbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.text = instruction.parameters.get("label", "START")
	line_edit.custom_minimum_size = Vector2(150, 0)
	line_edit.text_changed.connect(func(new_text):
		instruction.parameters["label"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	hbox.add_child(line_edit)
	
	return hbox


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


## Creates CONDITION parameter UI
func _create_condition_params(instruction, index: int) -> Control:
	var vbox = VBoxContainer.new()
	
	# Condition type dropdown
	var type_hbox = HBoxContainer.new()
	var type_label = Label.new()
	type_label.text = "Condition:"
	type_hbox.add_child(type_label)
	
	var type_option = OptionButton.new()
	type_option.add_item("IS_HEALTH_LOW", 0)
	type_option.add_item("IS_ENEMY_NEARBY", 1)
	type_option.add_item("IS_ENEMY_IN_RANGE", 2)
	
	var current_type = instruction.parameters.get("condition_type", "IS_HEALTH_LOW")
	match current_type:
		"IS_HEALTH_LOW": type_option.selected = 0
		"IS_ENEMY_NEARBY": type_option.selected = 1
		"IS_ENEMY_IN_RANGE": type_option.selected = 2
	
	type_option.item_selected.connect(func(idx):
		var types = ["IS_HEALTH_LOW", "IS_ENEMY_NEARBY", "IS_ENEMY_IN_RANGE"]
		instruction.parameters["condition_type"] = types[idx]
		EventBus.program_edited.emit(current_program)
	)
	type_hbox.add_child(type_option)
	vbox.add_child(type_hbox)
	
	# Jump targets
	var true_hbox = HBoxContainer.new()
	var true_label = Label.new()
	true_label.text = "If true, jump to:"
	true_hbox.add_child(true_label)
	
	var true_edit = LineEdit.new()
	true_edit.text = instruction.parameters.get("jump_if_true", "")
	true_edit.custom_minimum_size = Vector2(100, 0)
	true_edit.text_changed.connect(func(new_text):
		instruction.parameters["jump_if_true"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	true_hbox.add_child(true_edit)
	vbox.add_child(true_hbox)
	
	var false_hbox = HBoxContainer.new()
	var false_label = Label.new()
	false_label.text = "If false, jump to:"
	false_hbox.add_child(false_label)
	
	var false_edit = LineEdit.new()
	false_edit.text = instruction.parameters.get("jump_if_false", "")
	false_edit.custom_minimum_size = Vector2(100, 0)
	false_edit.text_changed.connect(func(new_text):
		instruction.parameters["jump_if_false"] = new_text
		EventBus.program_edited.emit(current_program)
	)
	false_hbox.add_child(false_edit)
	vbox.add_child(false_hbox)
	
	return vbox


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
			"MOVE":
				return InstructionScript.new("MOVE", 2, {"direction": "forward", "distance": 1.0})
			"ATTACK":
				return InstructionScript.new("ATTACK", 3, {})
			"GOTO":
				return InstructionScript.new("GOTO", 1, {"label": "START"})
			"LABEL":
				return InstructionScript.new("LABEL", 0, {"name": "START"})
			"CONDITION":
				return InstructionScript.new("CONDITION", 2, {
					"condition_type": "IS_HEALTH_LOW",
					"jump_if_true": "",
					"jump_if_false": ""
				})
			_:
				return InstructionScript.new(block_type, 1, {})


## Callback when delete instruction button is pressed.
func _on_delete_instruction_pressed(index: int) -> void:
	if not current_program:
		push_error("[BlockEditor] Cannot delete instruction - program is null")
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
