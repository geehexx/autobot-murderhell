## SimulationManager - manages the game simulation during a Run.
## Coordinates systems and entities in the Simulation Context.
extends Node

# Preload required classes
const MovementSystemScript = preload("res://scripts/simulation/systems/movement_system.gd")
const CombatSystemScript = preload("res://scripts/simulation/systems/combat_system.gd")
const LevelScript = preload("res://scripts/simulation/level.gd")
const AndroidEntityScript = preload("res://scripts/simulation/android_entity.gd")
const ProgramScript = preload("res://scripts/core/program.gd")

## References to systems.
var movement_system
var combat_system

## Current level.
var current_level = null

## Player android.
var player_android = null

## Is simulation running?
var is_running: bool = false


func _ready() -> void:
	# Initialize systems
	movement_system = MovementSystemScript.new()
	add_child(movement_system)
	
	combat_system = CombatSystemScript.new()
	add_child(combat_system)
	
	# Connect to EventBus
	EventBus.run_started.connect(_on_run_started)
	
	print("[SimulationManager] Initialized")


func _process(delta: float) -> void:
	if not is_running:
		return
	
	# Process systems
	movement_system.process_movement(delta)


## Starts a new run.
func _on_run_started(level_id: String, program) -> void:
	print("[SimulationManager] Starting run on level: %s" % level_id)
	
	# Load level
	_load_level(level_id)
	
	# Create player android
	_create_player_android(program)
	
	# Start the level
	if current_level and player_android:
		current_level.start_level(player_android)
		# Connect player destroyed signal
		EventBus.android_destroyed.connect(_on_android_destroyed)
	
	is_running = true


## Loads a level.
func _load_level(level_id: String) -> void:
	# Clean up previous level
	if current_level:
		current_level.queue_free()
		current_level = null
	
	# Load level scene
	var level_path: String = "res://scenes/levels/%s.tscn" % level_id
	
	# Try tutorial level
	if level_id == "level_1":
		level_path = "res://scenes/levels/level_1_tutorial.tscn"
	
	if not ResourceLoader.exists(level_path):
		push_error("[SimulationManager] Level not found: %s" % level_path)
		return
	
	var level_scene: PackedScene = load(level_path)
	if not level_scene:
		push_error("[SimulationManager] Failed to load level: %s" % level_path)
		return
	
	current_level = level_scene.instantiate()
	add_child(current_level)
	
	print("[SimulationManager] Loaded level: %s" % level_id)


## Creates the player android with the given program.
func _create_player_android(program) -> void:
	player_android = AndroidEntityScript.new()
	player_android.android_name = "Player Android"
	player_android.faction = "player"
	player_android.position = Vector2(100, 100)
	player_android.add_to_group("androids")
	
	# Add visual representation
	_add_android_visual(player_android, Color(0.3, 0.7, 1.0))
	
	add_child(player_android)
	
	# Inject systems into AI core
	if player_android.ai_core:
		player_android.ai_core.movement_system = movement_system
		player_android.ai_core.combat_system = combat_system
	
	# Load program
	var success: bool = player_android.load_program(program)
	if success:
		player_android.start_ai()
		print("[SimulationManager] Player android created and AI started")
	else:
		push_error("[SimulationManager] Failed to load program into android")


## Stops the current run.
func stop_run() -> void:
	is_running = false
	
	if player_android:
		player_android.queue_free()
		player_android = null
	
	if current_level:
		current_level.queue_free()
		current_level = null
	
	EventBus.run_ended.emit({"success": false, "stopped": true})


## Adds visual representation to an android.
func _add_android_visual(android, color: Color) -> void:
	var visuals: Node2D = Node2D.new()
	visuals.name = "Visuals"
	
	# Body
	var body: ColorRect = ColorRect.new()
	body.offset_left = -20.0
	body.offset_top = -20.0
	body.offset_right = 20.0
	body.offset_bottom = 20.0
	body.color = color
	visuals.add_child(body)
	
	# Label
	var label: Label = Label.new()
	label.offset_left = -40.0
	label.offset_top = -40.0
	label.offset_right = 40.0
	label.offset_bottom = -20.0
	label.text = android.android_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visuals.add_child(label)
	
	android.add_child(visuals)


## Callback when an android is destroyed.
func _on_android_destroyed(android: Node) -> void:
	if android == player_android:
		print("[SimulationManager] Player android destroyed!")
		# Level will handle the lose condition
