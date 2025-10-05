## GameController - orchestrates the core gameplay loop.
## Manages transitions between Design, Deploy, Analyze, Iterate phases.
extends Node

# Preload required classes
const AITranslationServiceScript = preload("res://scripts/services/ai_translation_service.gd")
const PersistenceServiceScript = preload("res://scripts/services/persistence_service.gd")
const PlayerProfileScript = preload("res://scripts/progression/player_profile.gd")
const ProgramScript = preload("res://scripts/core/program.gd")

## Current game phase.
enum Phase {
	DESIGN,    # Player edits their AI program
	DEPLOY,    # Program is translated and Android is deployed
	ANALYZE,   # Player debugs and analyzes the Run
	ITERATE    # Player returns to Design to improve
}

var current_phase: Phase = Phase.DESIGN

## Services.
var translation_service
var persistence_service

## Player profile.
var player_profile


func _ready() -> void:
	print("[GameController] Initializing...")
	
	# Initialize services
	translation_service = AITranslationServiceScript.new()
	add_child(translation_service)
	
	persistence_service = PersistenceServiceScript.new()
	add_child(persistence_service)
	
	# Load player profile
	var load_result: Dictionary = persistence_service.load_profile()
	player_profile = PlayerProfileScript.new()
	if load_result["success"]:
		player_profile.from_dictionary(load_result["data"])
	
	# Connect to EventBus
	EventBus.translate_program_requested.connect(_on_translate_program_requested)
	EventBus.run_ended.connect(_on_run_ended)
	
	# Set up UI
	_setup_ui()
	
	print("[GameController] Initialized in DESIGN phase")
	_maybe_quit_for_headless_check()


## Sets up UI with player profile.
func _setup_ui() -> void:
	var block_editor: Control = get_node("UILayer/TabContainer/Design/BlockEditor")
	if block_editor and block_editor.has_method("set_player_profile"):
		block_editor.set_player_profile(player_profile)


## Handles program translation request.
func _on_translate_program_requested(program) -> void:
	print("[GameController] Translating program...")
	var result: Dictionary = translation_service.translate_program(program)
	
	if result["success"]:
		print("[GameController] Translation successful, transitioning to DEPLOY phase")
		current_phase = Phase.DEPLOY
	else:
		print("[GameController] Translation failed: %s" % result["error"])


## Handles run ended.
func _on_run_ended(result: Dictionary) -> void:
	print("[GameController] Run ended, transitioning to ANALYZE phase")
	current_phase = Phase.ANALYZE
	
	# Record run statistics
	var success: bool = result.get("success", false)
	player_profile.record_run(success)


## Saves the game.
func save_game() -> void:
	var profile_dict: Dictionary = player_profile.to_dictionary()
	persistence_service.save_profile(profile_dict)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save on exit
		save_game()


func _maybe_quit_for_headless_check() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	if "--check-only" in args:
		print("[GameController] --check-only detected, scheduling exit.")
		call_deferred("_quit_after_startup")


func _quit_after_startup() -> void:
	var tree := get_tree()
	if tree:
		tree.quit()
