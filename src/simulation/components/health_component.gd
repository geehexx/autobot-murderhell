## Health Component for Entities.
## Manages health, armor, and damage calculation.
## This is a data component in the Entity-Component pattern.
class_name HealthComponent
extends Node


## Maximum health of this entity.
@export var max_health: float = 100.0

## Current health of this entity.
@export var current_health: float = 100.0

## Armor value that reduces incoming damage.
@export var armor: float = 0.0

## Whether this entity is currently alive.
var is_alive: bool = true


func _ready() -> void:
	current_health = max_health


## Takes damage, accounting for armor mitigation.
## Returns the actual damage dealt after mitigation.
## Emits android_damaged signal via EventBus.
func take_damage(damage: float, source: Node = null) -> float:
	if not is_alive:
		return 0.0
	
	# Simple armor formula: each point of armor reduces damage by 1%
	var mitigation: float = min(armor * 0.01, 0.75)  # Max 75% reduction
	var actual_damage: float = damage * (1.0 - mitigation)
	
	current_health -= actual_damage
	
	# Emit damage event
	if get_parent():
		EventBus.android_damaged.emit(get_parent(), actual_damage, source)
	
	# Check if dead
	if current_health <= 0.0:
		current_health = 0.0
		is_alive = false
		if get_parent():
			EventBus.android_destroyed.emit(get_parent())
	
	return actual_damage


## Heals the entity by the specified amount.
## Cannot exceed max_health.
func heal(amount: float) -> void:
	if not is_alive:
		return
	
	current_health = min(current_health + amount, max_health)


## Returns the current health as a percentage (0.0 to 1.0).
func get_health_percentage() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health


## Returns true if health is below the specified percentage threshold.
func is_health_low(threshold: float = 0.25) -> bool:
	return get_health_percentage() < threshold


## Resets health to maximum.
func reset() -> void:
	current_health = max_health
	is_alive = true
