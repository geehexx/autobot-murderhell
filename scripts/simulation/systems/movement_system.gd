## MovementSystem - handles Android movement in the simulation.
## Part of the Entity-Component pattern systems layer.
class_name MovementSystem
extends Node


## Movement speed in pixels per second.
const DEFAULT_SPEED: float = 100.0


func _ready() -> void:
	print("[MovementSystem] Initialized")


## Processes movement for all Androids in the "androids" group.
func process_movement(delta: float) -> void:
	var androids: Array[Node] = get_tree().get_nodes_in_group("androids")
	
	for node in androids:
		if node is AndroidEntity:
			_process_android_movement(node, delta)


## Processes movement for a single Android.
func _process_android_movement(android: AndroidEntity, delta: float) -> void:
	# Placeholder - in full implementation, this would read movement commands
	# from the AI Core's execution state and apply velocity
	pass


## Moves an Android in a direction.
func move_android(android: AndroidEntity, direction: Vector2, speed: float = DEFAULT_SPEED) -> void:
	if not android.is_alive():
		return
	
	var normalized_direction: Vector2 = direction.normalized()
	var velocity: Vector2 = normalized_direction * speed
	
	# Simple movement (no collision detection yet)
	android.position += velocity * get_process_delta_time()


## Moves an Android forward relative to its rotation.
func move_forward(android: AndroidEntity, distance: float = 1.0) -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(android.rotation)
	android.position += direction * distance


## Rotates an Android to face a target position.
func face_target(android: AndroidEntity, target_position: Vector2) -> void:
	var direction: Vector2 = target_position - android.position
	android.rotation = direction.angle()


## Checks if movement is possible (no obstacles).
func can_move_to(android: AndroidEntity, target_position: Vector2) -> bool:
	# Placeholder - would perform collision checks
	return true
