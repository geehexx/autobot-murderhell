## CombatSystem - handles combat interactions between Androids.
## Part of the Entity-Component pattern systems layer.
class_name CombatSystem
extends Node

# Preload required classes
const AndroidEntityScript = preload("res://scripts/simulation/android_entity.gd")

## Default values.
const DEFAULT_DAMAGE: float = 10.0
const DEFAULT_RANGE: float = 100.0


func _ready() -> void:
	print("[CombatSystem] Initialized")


## Performs an attack from one Android to another.
## Returns true if attack was successful.
func perform_attack(attacker, target, damage: float = DEFAULT_DAMAGE) -> bool:
	if not attacker.is_alive():
		print("[CombatSystem] Attacker is dead, cannot attack")
		return false
	
	if not target.is_alive():
		print("[CombatSystem] Target is already dead")
		return false
	
	# Check range
	var distance: float = attacker.position.distance_to(target.position)
	if distance > DEFAULT_RANGE:
		print("[CombatSystem] Target out of range (%f > %f)" % [distance, DEFAULT_RANGE])
		return false
	
	# Apply damage
	print("[CombatSystem] %s attacks %s for %f damage" % [
		attacker.android_name,
		target.android_name,
		damage
	])
	
	target.take_damage(damage, attacker)
	return true


## Finds the nearest enemy Android to the given Android.
func find_nearest_enemy(android, search_radius: float = 500.0):
	var androids: Array[Node] = get_tree().get_nodes_in_group("androids")
	var nearest_enemy = null
	var nearest_distance: float = search_radius
	
	for node in androids:
		# All nodes in 'androids' group should be AndroidEntity instances
		if not node.has_method("load_program"):
			continue
		
		var other = node
		
		# Skip self
		if other == android:
			continue
		
		# Skip same faction
		if other.faction == android.faction:
			continue
		# Skip dead enemies
		if not other.is_alive():
			continue
		
		# Check distance
		var distance: float = android.position.distance_to(other.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = other
	
	return nearest_enemy


## Checks if target is in attack range.
func is_in_attack_range(attacker, target, range: float = DEFAULT_RANGE) -> bool:
	if not target or not target.is_alive():
		return false
	
	var distance: float = attacker.position.distance_to(target.position)
	return distance <= range


## Gets all enemies within a radius.
func get_enemies_in_radius(android, radius: float) -> Array:
	var enemies: Array = []
	var androids: Array[Node] = get_tree().get_nodes_in_group("androids")
	
	for node in androids:
		# All nodes in 'androids' group should be AndroidEntity instances
		if not node.has_method("load_program"):
			continue
		
		var other = node
		
		# Skip self and same faction
		if other == android or other.faction == android.faction:
			continue
		
		# Skip dead
		if not other.is_alive():
			continue
		
		# Check distance
		if android.position.distance_to(other.position) <= radius:
			enemies.append(other)
	
	return enemies
