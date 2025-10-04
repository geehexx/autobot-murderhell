## SimulationManager - manages the game simulation during a Run.
## Coordinates systems and entities in the Simulation Context.
extends Node


## References to systems.
var movement_system: MovementSystem
var combat_system: CombatSystem

## Current level.
var current_level: Node = null

## Player android.
var player_android: AndroidEntity = null

## Is simulation running?
var is_running: bool = false


func _ready() -> void:
	# Initialize systems
	movement_system = MovementSystem.new()
	add_child(movement_system)
	
	combat_system = CombatSystem.new()
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
func _on_run_started(level_id: String, program: Program) -> void:
	print("[SimulationManager] Starting run on level: %s" % level_id)
	
	# Load level (placeholder - would load actual level scene)
	_load_level(level_id)
	
	# Create player android
	_create_player_android(program)
	
	is_running = true


## Loads a level.
func _load_level(level_id: String) -> void:
	# Placeholder - would load actual level scene
	print("[SimulationManager] Loading level: %s" % level_id)


## Creates the player android with the given program.
func _create_player_android(program: Program) -> void:
	player_android = AndroidEntity.new()
	player_android.android_name = "Player Android"
	player_android.faction = "player"
	player_android.position = Vector2(100, 100)
	player_android.add_to_group("androids")
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
	
	EventBus.run_ended.emit({"success": false, "stopped": true})
