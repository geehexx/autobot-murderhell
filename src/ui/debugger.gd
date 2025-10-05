## Debugger UI - for analyzing Run execution.
## Mobile-first design for the "Analyze" phase of the core loop.
extends Control

# Preload required classes
const ProgramScript = preload("res://src/core/program.gd")
const InstructionScript = preload("res://src/core/instruction.gd")

## Current program being debugged.
var current_program = null

## Current instruction pointer.
var current_instruction_index: int = 0

## Current execution state.
var current_state: Dictionary = {}

## Is execution paused?
var is_paused: bool = false

## UI references.
@onready var instruction_list: VBoxContainer = %InstructionList
@onready var state_display: RichTextLabel = %StateDisplay
@onready var play_pause_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/PlayPauseButton
@onready var step_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/StepButton
@onready var stop_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/StopButton


func _ready() -> void:
	# Connect buttons
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	step_button.pressed.connect(_on_step_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	
	# Connect to EventBus
	EventBus.instruction_executed.connect(_on_instruction_executed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	
	print("[Debugger] Initialized")


## Loads a program into the debugger.
func load_program(program) -> void:
	if not program:
		return
	
	current_program = program
	current_instruction_index = 0
	_refresh_instruction_display()
	print("[Debugger] Loaded program: %s" % program.program_name)


## Refreshes the instruction list display.
func _refresh_instruction_display() -> void:
	# Clear existing
	for child in instruction_list.get_children():
		child.queue_free()
	
	if not current_program:
		return
	
	# Display each instruction
	for i in current_program.instructions.size():
		var instruction = current_program.instructions[i]
		var panel: PanelContainer = PanelContainer.new()
		var label: Label = Label.new()
		
		# Highlight current instruction
		if i == current_instruction_index:
			panel.modulate = Color.YELLOW
		
		label.text = "%d: %s (CPU: %d)" % [i, instruction.type, instruction.cpu_cost]
		panel.add_child(label)
		instruction_list.add_child(panel)


## Updates the state display.
func _update_state_display(state: Dictionary) -> void:
	current_state = state
	
	var text: String = "[b]Variables:[/b]\n"
	var variables: Dictionary = state.get("variables", {})
	for var_name in variables:
		text += "%s: %s\n" % [var_name, str(variables[var_name])]
	
	text += "\n[b]Memory Cells:[/b]\n"
	var memory: Array = state.get("memory", [])
	for i in memory.size():
		text += "[%d]: %s\n" % [i, str(memory[i])]
	
	state_display.text = text


## Callback when play/pause button is pressed.
func _on_play_pause_pressed() -> void:
	is_paused = not is_paused
	play_pause_button.text = "Resume" if is_paused else "Pause"
	step_button.disabled = not is_paused
	
	EventBus.debug_pause_toggled.emit(is_paused)
	print("[Debugger] Execution %s" % ("paused" if is_paused else "resumed"))


## Callback when step button is pressed.
func _on_step_pressed() -> void:
	EventBus.debug_step_requested.emit()
	print("[Debugger] Step forward")


## Callback when stop button is pressed.
func _on_stop_pressed() -> void:
	EventBus.run_ended.emit({"success": false, "stopped_manually": true})
	print("[Debugger] Execution stopped")


## Callback when an instruction is executed.
func _on_instruction_executed(instruction_index: int, state: Dictionary) -> void:
	current_instruction_index = instruction_index
	_refresh_instruction_display()
	_update_state_display(state)


## Callback when a run starts.
func _on_run_started(level_id: String, program) -> void:
	load_program(program)
	is_paused = false
	play_pause_button.text = "Pause"
	step_button.disabled = true
	print("[Debugger] Run started on level: %s" % level_id)


## Callback when a run ends.
func _on_run_ended(result: Dictionary) -> void:
	print("[Debugger] Run ended: %s" % str(result))
