## Level - represents a game level/dungeon.
## Contains spawn points, enemies, objectives, and win/lose conditions.
## Note: This script uses the preload pattern (ADR-002) instead of class_name.
extends Node2D

# Preload required classes
const AndroidEntityScript = preload("res://scripts/simulation/android_entity.gd")

## Level identification.
@export var level_id: String = "level_1"
@export var level_name: String = "Tutorial"

## Spawn point for player android.
@export var player_spawn_position: Vector2 = Vector2(100, 100)

## Win/lose conditions.
enum WinCondition {
	DEFEAT_ALL_ENEMIES,  # Kill all enemies
	REACH_EXIT,          # Reach the exit zone
	SURVIVE_TIME         # Survive for X seconds
}

@export var win_condition: WinCondition = WinCondition.DEFEAT_ALL_ENEMIES
@export var time_limit: float = 0.0  # 0 = no limit

## Level state.
var is_active: bool = false
var elapsed_time: float = 0.0
var player_android = null
var enemy_androids: Array = []


func _ready() -> void:
	add_to_group("levels")
	print("[Level] '%s' initialized" % level_name)


func _process(delta: float) -> void:
	if not is_active:
		return
	
	elapsed_time += delta
	
	# Check time limit
	if time_limit > 0.0 and elapsed_time >= time_limit:
		_trigger_lose_condition("Time limit exceeded")
	
	# Check win conditions
	_check_win_conditions()


## Starts the level.
func start_level(p_player_android) -> void:
	player_android = p_player_android
	is_active = true
	elapsed_time = 0.0
	
	# Position player at spawn
	if player_android:
		player_android.position = player_spawn_position
	
	# Find all enemy androids
	_find_enemies()
	
	# Give enemies default AI
	_setup_enemy_ai()
	
	print("[Level] Started: %s (Enemies: %d)" % [level_name, enemy_androids.size()])


## Finds all enemy androids in the level.
func _find_enemies() -> void:
	enemy_androids.clear()
	
	var androids: Array[Node] = get_tree().get_nodes_in_group("androids")
	for node in androids:
		# All nodes in 'androids' group should be AndroidEntity instances
		if node.has_method("load_program"):
			var android = node
			if android != player_android and android.faction == "enemy":
				enemy_androids.append(android)


## Checks if win conditions are met.
func _check_win_conditions() -> void:
	match win_condition:
		WinCondition.DEFEAT_ALL_ENEMIES:
			if _are_all_enemies_defeated():
				_trigger_win_condition()
		WinCondition.REACH_EXIT:
			if _is_player_at_exit():
				_trigger_win_condition()
		WinCondition.SURVIVE_TIME:
			if elapsed_time >= time_limit:
				_trigger_win_condition()


## Checks if all enemies are defeated.
func _are_all_enemies_defeated() -> bool:
	for enemy in enemy_androids:
		if enemy and enemy.is_alive():
			return false
	return true


## Checks if player reached the exit (placeholder).
func _is_player_at_exit() -> bool:
	# TODO: Implement exit zone detection
	return false


## Triggers win condition.
func _trigger_win_condition() -> void:
	if not is_active:
		return
	
	is_active = false
	print("[Level] Win condition met!")
	
	EventBus.run_ended.emit({
		"success": true,
		"level_id": level_id,
		"time": elapsed_time,
		"enemies_defeated": enemy_androids.size()
	})


## Triggers lose condition.
func _trigger_lose_condition(reason: String) -> void:
	if not is_active:
		return
	
	is_active = false
	print("[Level] Lose condition met: %s" % reason)
	
	EventBus.run_ended.emit({
		"success": false,
		"level_id": level_id,
		"reason": reason,
		"time": elapsed_time
	})


## Callback when player android is destroyed.
func _on_player_destroyed() -> void:
	_trigger_lose_condition("Player android destroyed")


## Returns the number of living enemies.
func get_living_enemy_count() -> int:
	var count: int = 0
	for enemy in enemy_androids:
		if enemy and enemy.is_alive():
			count += 1
	return count


## Sets up default AI for enemy androids.
func _setup_enemy_ai() -> void:
	# Get systems from SimulationManager
	var sim_manager = get_parent()
	if not sim_manager or not sim_manager.has_method("_create_player_android"):
		push_error("[Level] Cannot setup enemy AI - SimulationManager not found")
		return
	
	# Create a simple default enemy program (stand and attack when player approaches)
	const ProgramScript = preload("res://scripts/core/program.gd")
	const InstructionScript = preload("res://scripts/core/instruction.gd")
	
	var enemy_program = ProgramScript.new("Enemy AI")
	enemy_program.add_instruction(InstructionScript.new("LABEL", 0, {"name": "START"}))
	enemy_program.add_instruction(InstructionScript.new("ATTACK", 3, {}))
	enemy_program.add_instruction(InstructionScript.new("GOTO", 1, {"label": "START"}))
	
	# Load program into each enemy
	for enemy in enemy_androids:
		if enemy and enemy.has_method("load_program") and enemy.ai_core:
			# Inject systems into enemy AI core
			if sim_manager.movement_system:
				enemy.ai_core.movement_system = sim_manager.movement_system
			if sim_manager.combat_system:
				enemy.ai_core.combat_system = sim_manager.combat_system
			
			# Load and start program
			if enemy.load_program(enemy_program):
				enemy.start_ai()
				print("[Level] Enemy '%s' AI initialized" % enemy.android_name)
			else:
				push_error("[Level] Failed to load program into enemy '%s'" % enemy.android_name)
