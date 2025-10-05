## Android Entity - the aggregate root for the Simulation Context.
## Represents a player or enemy Android in the game world.
## Composed of Components following the Entity-Component pattern.
class_name AndroidEntity
extends Node2D

# Preload required classes
const HealthComponentScript = preload("res://scripts/simulation/components/health_component.gd")
const AICoreComponentScript = preload("res://scripts/simulation/components/ai_core_component.gd")

## Reference to the HealthComponent.
var health_component = null

## Reference to the AICoreComponent.
var ai_core = null

## The Android's display name.
@export var android_name: String = "Android"

## The Android's faction ("player", "enemy", "neutral").
@export var faction: String = "neutral"


func _ready() -> void:
	# Create components
	if not has_node("HealthComponent"):
		var health = HealthComponentScript.new()
		health.name = "HealthComponent"
		add_child(health)
		health_component = health
	else:
		health_component = get_node("HealthComponent")
	
	if not has_node("AICoreComponent"):
		var ai = AICoreComponentScript.new()
		ai.name = "AICoreComponent"
		add_child(ai)
		ai_core = ai
	else:
		ai_core = get_node("AICoreComponent")
	
	print("[AndroidEntity] '%s' initialized (Faction: %s)" % [android_name, faction])


func _process(_delta: float) -> void:
	# Execute AI if active
	if ai_core and ai_core.is_executing:
		ai_core.execute_step()


## Loads an AI Program into this Android.
func load_program(program) -> bool:
	if not ai_core:
		push_error("[AndroidEntity] No AI Core component")
		return false
	
	return ai_core.load_program(program)


## Starts AI execution.
func start_ai() -> void:
	if ai_core:
		ai_core.start_execution()


## Stops AI execution.
func stop_ai() -> void:
	if ai_core:
		ai_core.stop_execution()


## Takes damage.
func take_damage(damage: float, source: Node = null) -> float:
	if health_component:
		return health_component.take_damage(damage, source)
	return 0.0


## Checks if this Android is alive.
func is_alive() -> bool:
	if health_component:
		return health_component.is_alive
	return false


## Returns health percentage.
func get_health_percentage() -> float:
	if health_component:
		return health_component.get_health_percentage()
	return 0.0
