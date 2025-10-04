## PlayerProfile - aggregate root for the Progression Context.
## Manages player progression, unlocks, and resources.
class_name PlayerProfile
extends Resource


## Player's display name.
@export var player_name: String = "Player"

## Game version this profile was created/last saved with.
@export var version: String = "0.1.0"

## Current level the player is on.
@export var current_level: int = 1

## List of completed level IDs.
@export var levels_completed: Array[int] = []

## Resources (currency).
var resources: Dictionary = {
	"credits": 0,
	"data_shards": 0
}

## Unlocked instruction blocks.
var unlocked_blocks: Array[String] = []

## Unlocked chips/hardware.
var unlocked_chips: Array[String] = []

## Upgrade tree state (node_id -> purchased).
var upgrade_tree_state: Dictionary = {}

## Game statistics.
var statistics: Dictionary = {
	"total_runs": 0,
	"successful_runs": 0,
	"total_playtime_seconds": 0
}


func _init() -> void:
	_initialize_defaults()


## Initializes default values for a new profile.
func _initialize_defaults() -> void:
	# Start with basic instruction blocks
	unlocked_blocks = ["MOVE", "GOTO", "LABEL"]
	resources = {"credits": 0, "data_shards": 0}


## Converts this profile to a saveable Dictionary.
func to_dictionary() -> Dictionary:
	return {
		"version": version,
		"player_name": player_name,
		"current_level": current_level,
		"levels_completed": levels_completed.duplicate(),
		"resources": resources.duplicate(true),
		"unlocked_blocks": unlocked_blocks.duplicate(),
		"unlocked_chips": unlocked_chips.duplicate(),
		"upgrade_tree_state": upgrade_tree_state.duplicate(true),
		"statistics": statistics.duplicate(true)
	}


## Loads profile data from a Dictionary.
func from_dictionary(data: Dictionary) -> void:
	version = data.get("version", "0.1.0")
	player_name = data.get("player_name", "Player")
	current_level = data.get("current_level", 1)
	levels_completed = data.get("levels_completed", []).duplicate()
	resources = data.get("resources", {"credits": 0, "data_shards": 0}).duplicate(true)
	unlocked_blocks = data.get("unlocked_blocks", ["MOVE", "GOTO", "LABEL"]).duplicate()
	unlocked_chips = data.get("unlocked_chips", []).duplicate()
	upgrade_tree_state = data.get("upgrade_tree_state", {}).duplicate(true)
	statistics = data.get("statistics", {
		"total_runs": 0,
		"successful_runs": 0,
		"total_playtime_seconds": 0
	}).duplicate(true)


## Checks if a block is unlocked.
func is_block_unlocked(block_id: String) -> bool:
	return unlocked_blocks.has(block_id)


## Checks if a chip is unlocked.
func is_chip_unlocked(chip_id: String) -> bool:
	return unlocked_chips.has(chip_id)


## Unlocks a new instruction block.
func unlock_block(block_id: String) -> void:
	if not is_block_unlocked(block_id):
		unlocked_blocks.append(block_id)
		EventBus.capability_unlocked.emit("block", block_id)
		print("[PlayerProfile] Unlocked block: %s" % block_id)


## Unlocks a new chip.
func unlock_chip(chip_id: String) -> void:
	if not is_chip_unlocked(chip_id):
		unlocked_chips.append(chip_id)
		EventBus.capability_unlocked.emit("chip", chip_id)
		print("[PlayerProfile] Unlocked chip: %s" % chip_id)


## Adds resources.
func add_resources(resource_type: String, amount: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] += amount
		EventBus.resources_changed.emit(resource_type, resources[resource_type])
		print("[PlayerProfile] Added %d %s (Total: %d)" % [amount, resource_type, resources[resource_type]])


## Spends resources. Returns true if successful, false if insufficient.
func spend_resources(resource_type: String, amount: int) -> bool:
	if not resources.has(resource_type):
		return false
	
	if resources[resource_type] < amount:
		return false
	
	resources[resource_type] -= amount
	EventBus.resources_changed.emit(resource_type, resources[resource_type])
	print("[PlayerProfile] Spent %d %s (Remaining: %d)" % [amount, resource_type, resources[resource_type]])
	return true


## Checks if player can afford a cost.
func can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var cost: int = costs[resource_type]
		if not resources.has(resource_type) or resources[resource_type] < cost:
			return false
	return true


## Purchases an upgrade from the tree.
## Returns true if successful, false if already purchased or can't afford.
func purchase_upgrade(upgrade_id: String, cost: Dictionary) -> bool:
	# Check if already purchased
	if upgrade_tree_state.get(upgrade_id, false):
		print("[PlayerProfile] Upgrade '%s' already purchased" % upgrade_id)
		return false
	
	# Check if can afford
	if not can_afford(cost):
		print("[PlayerProfile] Cannot afford upgrade '%s'" % upgrade_id)
		return false
	
	# Spend resources
	for resource_type in cost:
		spend_resources(resource_type, cost[resource_type])
	
	# Mark as purchased
	upgrade_tree_state[upgrade_id] = true
	EventBus.upgrade_purchased.emit(upgrade_id)
	print("[PlayerProfile] Purchased upgrade: %s" % upgrade_id)
	return true


## Marks a level as completed.
func complete_level(level_id: int, reward: Dictionary) -> void:
	if not levels_completed.has(level_id):
		levels_completed.append(level_id)
		print("[PlayerProfile] Level %d completed!" % level_id)
	
	# Award resources
	for resource_type in reward:
		add_resources(resource_type, reward[resource_type])


## Records a completed run.
func record_run(success: bool) -> void:
	statistics["total_runs"] += 1
	if success:
		statistics["successful_runs"] += 1


## Adds playtime.
func add_playtime(seconds: int) -> void:
	statistics["total_playtime_seconds"] += seconds


## Gets the success rate as a percentage.
func get_success_rate() -> float:
	var total: int = statistics.get("total_runs", 0)
	if total == 0:
		return 0.0
	
	var successful: int = statistics.get("successful_runs", 0)
	return (float(successful) / float(total)) * 100.0
