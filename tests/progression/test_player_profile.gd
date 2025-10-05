## Unit tests for PlayerProfile (Progression Context aggregate root).
extends GdUnitTestSuite


const PlayerProfileScript = preload("res://src/progression/player_profile.gd")


func test_player_profile_initialization() -> void:
	var profile = PlayerProfileScript.new()
	
	assert_str(profile.player_name).is_equal("Player")
	assert_str(profile.version).is_equal("0.1.0")
	assert_int(profile.current_level).is_equal(1)
	assert_array(profile.unlocked_blocks).is_not_empty()


func test_profile_starts_with_basic_blocks() -> void:
	var profile = PlayerProfileScript.new()
	
	assert_bool(profile.is_block_unlocked("MOVE")).is_true()
	assert_bool(profile.is_block_unlocked("GOTO")).is_true()
	assert_bool(profile.is_block_unlocked("LABEL")).is_true()


func test_unlock_block() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.unlock_block("ATTACK")
	
	assert_bool(profile.is_block_unlocked("ATTACK")).is_true()


func test_unlock_block_twice_only_adds_once() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.unlock_block("ATTACK")
	var initial_count: int = profile.unlocked_blocks.size()
	profile.unlock_block("ATTACK")
	
	assert_int(profile.unlocked_blocks.size()).is_equal(initial_count)


func test_unlock_chip() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.unlock_chip("TARGETING_CHIP")
	
	assert_bool(profile.is_chip_unlocked("TARGETING_CHIP")).is_true()


func test_add_resources() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.add_resources("credits", 100)
	
	assert_int(profile.resources["credits"]).is_equal(100)


func test_spend_resources_with_sufficient_amount() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 100)
	
	var result: bool = profile.spend_resources("credits", 50)
	
	assert_bool(result).is_true()
	assert_int(profile.resources["credits"]).is_equal(50)


func test_spend_resources_with_insufficient_amount() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 30)
	
	var result: bool = profile.spend_resources("credits", 50)
	
	assert_bool(result).is_false()
	assert_int(profile.resources["credits"]).is_equal(30)


func test_can_afford_with_sufficient_resources() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 100)
	profile.add_resources("data_shards", 20)
	
	var cost: Dictionary = {"credits": 50, "data_shards": 10}
	
	assert_bool(profile.can_afford(cost)).is_true()


func test_can_afford_with_insufficient_resources() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 30)
	
	var cost: Dictionary = {"credits": 50}
	
	assert_bool(profile.can_afford(cost)).is_false()


func test_purchase_upgrade_success() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 100)
	
	var cost: Dictionary = {"credits": 50}
	var result: bool = profile.purchase_upgrade("upgrade_cpu_1", cost)
	
	assert_bool(result).is_true()
	assert_bool(profile.upgrade_tree_state.get("upgrade_cpu_1", false)).is_true()
	assert_int(profile.resources["credits"]).is_equal(50)


func test_purchase_upgrade_already_purchased() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 100)
	
	var cost: Dictionary = {"credits": 50}
	profile.purchase_upgrade("upgrade_cpu_1", cost)
	var result: bool = profile.purchase_upgrade("upgrade_cpu_1", cost)
	
	assert_bool(result).is_false()


func test_purchase_upgrade_cannot_afford() -> void:
	var profile = PlayerProfileScript.new()
	profile.add_resources("credits", 30)
	
	var cost: Dictionary = {"credits": 50}
	var result: bool = profile.purchase_upgrade("upgrade_cpu_1", cost)
	
	assert_bool(result).is_false()
	assert_bool(profile.upgrade_tree_state.has("upgrade_cpu_1")).is_false()


func test_complete_level() -> void:
	var profile = PlayerProfileScript.new()
	var reward: Dictionary = {"credits": 100}
	
	profile.complete_level(1, reward)
	
	assert_array(profile.levels_completed).contains(1)
	assert_int(profile.resources["credits"]).is_equal(100)


func test_complete_level_twice_only_adds_once() -> void:
	var profile = PlayerProfileScript.new()
	var reward: Dictionary = {"credits": 100}
	
	profile.complete_level(1, reward)
	profile.complete_level(1, reward)
	
	assert_int(profile.levels_completed.count(1)).is_equal(1)
	assert_int(profile.resources["credits"]).is_equal(200)  # Rewards still given


func test_record_run_success() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.record_run(true)
	
	assert_int(profile.statistics["total_runs"]).is_equal(1)
	assert_int(profile.statistics["successful_runs"]).is_equal(1)


func test_record_run_failure() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.record_run(false)
	
	assert_int(profile.statistics["total_runs"]).is_equal(1)
	assert_int(profile.statistics["successful_runs"]).is_equal(0)


func test_get_success_rate() -> void:
	var profile = PlayerProfileScript.new()
	
	profile.record_run(true)
	profile.record_run(true)
	profile.record_run(false)
	
	var rate: float = profile.get_success_rate()
	
	assert_float(rate).is_equal(66.666667, 0.01)


func test_get_success_rate_with_no_runs() -> void:
	var profile = PlayerProfileScript.new()
	
	var rate: float = profile.get_success_rate()
	
	assert_float(rate).is_equal(0.0)


	var original = PlayerProfileScript.new()
	original.player_name = "TestPlayer"
	original.add_resources("credits", 500)
	original.unlock_block("ATTACK")
	original.unlock_chip("TARGETING_CHIP")
	original.complete_level(1, {})
	original.record_run(true)
	
	var dict: Dictionary = original.to_dictionary()
	var restored = PlayerProfileScript.new()
	restored.from_dictionary(dict)
	
	assert_str(restored.player_name).is_equal("TestPlayer")
	assert_int(restored.resources["credits"]).is_equal(500)
	assert_bool(restored.is_block_unlocked("ATTACK")).is_true()
	assert_bool(restored.is_chip_unlocked("TARGETING_CHIP")).is_true()
	assert_array(restored.levels_completed).contains(1)
	assert_int(restored.statistics["total_runs"]).is_equal(1)
