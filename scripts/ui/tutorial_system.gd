## TutorialSystem - manages step-by-step tutorial guidance.
## Uses State Machine pattern to manage tutorial progression.
extends CanvasLayer

## Tutorial states
enum TutorialState {
	INACTIVE,           # Tutorial not running
	WELCOME,           # Initial welcome message
	EXPLAIN_GOAL,      # Explain level objective
	ADD_MOVE_BLOCK,    # Guide player to add MOVE instruction
	ADD_ATTACK_BLOCK,  # Guide player to add ATTACK instruction
	DEPLOY_PROGRAM,    # Guide player to deploy their program
	WATCH_EXECUTION,   # Explain execution analysis
	VICTORY,           # Tutorial complete celebration
	COMPLETED          # Tutorial fully completed
}

## Current tutorial state
var current_state: TutorialState = TutorialState.INACTIVE

## Tutorial data for level 1
var level_1_tutorial: bool = true

## UI elements
var overlay_panel: Panel
var message_label: Label
var next_button: Button
var highlight_rect: ColorRect

## Track player progress
var blocks_added: Dictionary = {
	"MOVE": false,
	"ATTACK": false
}
var program_deployed: bool = false


func _ready() -> void:
	_create_ui()
	EventBus.instruction_added.connect(_on_instruction_added)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	print("[TutorialSystem] Initialized")


## Creates the tutorial UI overlay
func _create_ui() -> void:
	# Create overlay panel
	overlay_panel = Panel.new()
	overlay_panel.name = "TutorialOverlay"
	overlay_panel.offset_left = 50.0
	overlay_panel.offset_top = 50.0
	overlay_panel.offset_right = 550.0
	overlay_panel.offset_bottom = 250.0
	overlay_panel.visible = false
	add_child(overlay_panel)
	
	# Create message label
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.offset_left = 20.0
	message_label.offset_top = 20.0
	message_label.offset_right = 480.0
	message_label.offset_bottom = 150.0
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	overlay_panel.add_child(message_label)
	
	# Create next button
	next_button = Button.new()
	next_button.name = "NextButton"
	next_button.offset_left = 380.0
	next_button.offset_top = 160.0
	next_button.offset_right = 480.0
	next_button.offset_bottom = 190.0
	next_button.text = "Next"
	next_button.pressed.connect(_on_next_button_pressed)
	overlay_panel.add_child(next_button)
	
	# Create highlight rectangle (for highlighting UI elements)
	highlight_rect = ColorRect.new()
	highlight_rect.name = "Highlight"
	highlight_rect.color = Color(1.0, 1.0, 0.0, 0.3)
	highlight_rect.visible = false
	add_child(highlight_rect)


## Starts the tutorial for a specific level
func start_tutorial(level_id: String) -> void:
	if level_id == "level_1" or level_id == "level_1_tutorial":
		level_1_tutorial = true
		_transition_to_state(TutorialState.WELCOME)
	else:
		level_1_tutorial = false


## Stops the tutorial
func stop_tutorial() -> void:
	_transition_to_state(TutorialState.INACTIVE)


## Transitions to a new tutorial state
func _transition_to_state(new_state: TutorialState) -> void:
	# Exit current state
	_exit_state(current_state)
	
	# Update state
	var previous_state: TutorialState = current_state
	current_state = new_state
	
	# Enter new state
	_enter_state(current_state)
	
	print("[TutorialSystem] State transition: %s -> %s" % [
		TutorialState.keys()[previous_state],
		TutorialState.keys()[current_state]
	])


## Executes logic when entering a state
func _enter_state(state: TutorialState) -> void:
	match state:
		TutorialState.INACTIVE:
			overlay_panel.visible = false
			highlight_rect.visible = false
		
		TutorialState.WELCOME:
			_show_message(
				"Welcome to Autobot Murderhell!",
				"You are a programmer in a hostile digital world. Your androids execute the programs you write.\n\nLet's create your first AI program to defeat the enemy android."
			)
		
		TutorialState.EXPLAIN_GOAL:
			_show_message(
				"Mission Objective",
				"Your goal: Defeat all enemy androids.\n\nYou'll program your android to MOVE forward and ATTACK enemies.\n\nLet's start by adding a MOVE instruction."
			)
		
		TutorialState.ADD_MOVE_BLOCK:
			_show_message(
				"Step 1: Add MOVE Instruction",
				"Look at the Block Palette on the left.\n\nClick the 'MOVE' button to add a MOVE instruction to your program.\n\nThis tells your android to move forward.",
				false  # Don't show next button, wait for action
			)
			_highlight_element("BlockPalette")
		
		TutorialState.ADD_ATTACK_BLOCK:
			_show_message(
				"Step 2: Add ATTACK Instruction",
				"Great! Now add an ATTACK instruction.\n\nClick the 'ATTACK' button in the Block Palette.\n\nThis tells your android to attack nearby enemies.",
				false
			)
			_highlight_element("BlockPalette")
		
		TutorialState.DEPLOY_PROGRAM:
			_show_message(
				"Step 3: Deploy Your Program",
				"Perfect! Your program is ready.\n\nNow click the 'Deploy' button to send your android into action.",
				false
			)
			_highlight_element("DeployButton")
		
		TutorialState.WATCH_EXECUTION:
			_show_message(
				"Analyzing Execution",
				"Watch your android execute your program!\n\nThe Debugger shows which instruction is currently running.\n\nYou can pause, step through, or let it run automatically."
			)
			_highlight_element("Debugger")
		
		TutorialState.VICTORY:
			_show_message(
				"Victory!",
				"Congratulations! You've completed your first mission.\n\nYou can now iterate on your design, or proceed to the next level.\n\nRemember: Better programs earn more rewards!"
			)
		
		TutorialState.COMPLETED:
			overlay_panel.visible = false
			highlight_rect.visible = false
			print("[TutorialSystem] Tutorial completed")


## Executes logic when exiting a state
func _exit_state(state: TutorialState) -> void:
	# Clear highlights when leaving most states
	if state != TutorialState.INACTIVE:
		highlight_rect.visible = false


## Shows a tutorial message
func _show_message(title: String, message: String, show_next: bool = true) -> void:
	overlay_panel.visible = true
	message_label.text = "[b]%s[/b]\n\n%s" % [title, message]
	next_button.visible = show_next


## Highlights a UI element (simplified version)
func _highlight_element(element_name: String) -> void:
	# This is a simplified version. In a real implementation,
	# you'd find the actual UI node and position the highlight around it
	highlight_rect.visible = true
	
	match element_name:
		"BlockPalette":
			highlight_rect.offset_left = 10.0
			highlight_rect.offset_top = 100.0
			highlight_rect.offset_right = 210.0
			highlight_rect.offset_bottom = 400.0
		"DeployButton":
			highlight_rect.offset_left = 50.0
			highlight_rect.offset_top = 500.0
			highlight_rect.offset_right = 150.0
			highlight_rect.offset_bottom = 550.0
		"Debugger":
			highlight_rect.offset_left = 600.0
			highlight_rect.offset_top = 50.0
			highlight_rect.offset_right = 950.0
			highlight_rect.offset_bottom = 400.0
		_:
			highlight_rect.visible = false


## Called when next button is pressed
func _on_next_button_pressed() -> void:
	match current_state:
		TutorialState.WELCOME:
			_transition_to_state(TutorialState.EXPLAIN_GOAL)
		TutorialState.EXPLAIN_GOAL:
			_transition_to_state(TutorialState.ADD_MOVE_BLOCK)
		TutorialState.WATCH_EXECUTION:
			_transition_to_state(TutorialState.COMPLETED)
		TutorialState.VICTORY:
			_transition_to_state(TutorialState.COMPLETED)
		_:
			# For states that wait for actions, next button shouldn't advance
			pass


## Called when player adds an instruction
func _on_instruction_added(instruction) -> void:
	if not level_1_tutorial:
		return
	
	# Check instruction type
	if instruction.has("type"):
		var type: String = instruction["type"]
		blocks_added[type] = true
		
		# State machine logic
		if current_state == TutorialState.ADD_MOVE_BLOCK and type == "MOVE":
			_transition_to_state(TutorialState.ADD_ATTACK_BLOCK)
		elif current_state == TutorialState.ADD_ATTACK_BLOCK and type == "ATTACK":
			# Check if we have both blocks now
			if blocks_added.get("MOVE", false):
				_transition_to_state(TutorialState.DEPLOY_PROGRAM)


## Called when run starts
func _on_run_started(level_id: String, program) -> void:
	if not level_1_tutorial:
		return
	
	program_deployed = true
	
	if current_state == TutorialState.DEPLOY_PROGRAM:
		_transition_to_state(TutorialState.WATCH_EXECUTION)


## Called when run ends
func _on_run_ended(result: Dictionary) -> void:
	if not level_1_tutorial:
		return
	
	var success: bool = result.get("success", false)
	
	if current_state == TutorialState.WATCH_EXECUTION and success:
		_transition_to_state(TutorialState.VICTORY)


## Checks if tutorial should be active for this level
func should_show_tutorial(level_id: String) -> bool:
	# Check if player has completed tutorial before
	# This would integrate with PlayerProfile
	if level_id == "level_1" or level_id == "level_1_tutorial":
		return true  # Always show for first level in MVP
	return false
