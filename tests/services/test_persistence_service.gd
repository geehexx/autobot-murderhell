## Unit tests for PersistenceService.
extends GdUnitTestSuite


var persistence_service: PersistenceService


func before_test() -> void:
	persistence_service = PersistenceService.new()
	# Clean up any existing save files before each test
	persistence_service.delete_save_file()


func after_test() -> void:
	# Clean up after each test
	persistence_service.delete_save_file()


func test_save_valid_profile_succeeds() -> void:
	var profile_data: Dictionary = {
		"version": "0.1.0",
		"player_name": "TestPlayer",
		"resources": {"credits": 100},
		"unlocked_blocks": ["MOVE", "ATTACK"],
		"unlocked_chips": [],
		"upgrade_tree_state": {},
		"current_level": 1,
		"levels_completed": []
	}
	
	var result: bool = persistence_service.save_profile(profile_data)
	
	assert_bool(result).is_true()


func test_save_invalid_profile_fails() -> void:
	var invalid_profile: Dictionary = {
		"player_name": "TestPlayer"
		# Missing required keys
	}
	
	var result: bool = persistence_service.save_profile(invalid_profile)
	
	assert_bool(result).is_false()


func test_load_nonexistent_file_returns_default_profile() -> void:
	var result: Dictionary = persistence_service.load_profile()
	
	assert_bool(result["success"]).is_true()
	assert_dict(result["data"]).contains_key("version")
	assert_dict(result["data"]).contains_key("player_name")
	assert_dict(result["data"]).contains_key("resources")


func test_save_and_load_roundtrip() -> void:
	var original_profile: Dictionary = {
		"version": "0.1.0",
		"player_name": "TestPlayer",
		"resources": {"credits": 250, "data_shards": 10},
		"unlocked_blocks": ["MOVE", "ATTACK", "GOTO"],
		"unlocked_chips": ["TARGETING_CHIP"],
		"upgrade_tree_state": {"node_1": true},
		"current_level": 5,
		"levels_completed": [1, 2, 3, 4]
	}
	
	persistence_service.save_profile(original_profile)
	var result: Dictionary = persistence_service.load_profile()
	
	assert_bool(result["success"]).is_true()
	assert_str(result["data"]["player_name"]).is_equal("TestPlayer")
	assert_int(result["data"]["resources"]["credits"]).is_equal(250)
	assert_int(result["data"]["resources"]["data_shards"]).is_equal(10)
	assert_array(result["data"]["unlocked_blocks"]).contains("GOTO")
	assert_array(result["data"]["unlocked_chips"]).contains("TARGETING_CHIP")
	assert_int(result["data"]["current_level"]).is_equal(5)


func test_default_profile_has_required_keys() -> void:
	var result: Dictionary = persistence_service.load_profile()
	var profile: Dictionary = result["data"]
	
	assert_dict(profile).contains_key("version")
	assert_dict(profile).contains_key("player_name")
	assert_dict(profile).contains_key("resources")
	assert_dict(profile).contains_key("unlocked_blocks")
	assert_dict(profile).contains_key("unlocked_chips")
	assert_dict(profile).contains_key("upgrade_tree_state")
	assert_dict(profile).contains_key("current_level")
	assert_dict(profile).contains_key("levels_completed")


func test_default_profile_has_starter_blocks() -> void:
	var result: Dictionary = persistence_service.load_profile()
	var profile: Dictionary = result["data"]
	
	assert_array(profile["unlocked_blocks"]).contains("MOVE")
	assert_array(profile["unlocked_blocks"]).contains("GOTO")
	assert_array(profile["unlocked_blocks"]).contains("LABEL")


func test_save_emits_completion_event() -> void:
	var profile_data: Dictionary = {
		"version": "0.1.0",
		"player_name": "Test",
		"resources": {},
		"unlocked_blocks": [],
		"unlocked_chips": [],
		"upgrade_tree_state": {},
		"current_level": 1,
		"levels_completed": []
	}
	
	var signal_received: bool = false
	var signal_handler: Callable = func(_success: bool) -> void:
		signal_received = true
	
	EventBus.save_completed.connect(signal_handler)
	persistence_service.save_profile(profile_data)
	
	await await_idle_frame()
	
	assert_bool(signal_received).is_true()
	EventBus.save_completed.disconnect(signal_handler)


func test_load_emits_completion_event() -> void:
	var signal_received: bool = false
	var signal_handler: Callable = func(_success: bool, _data: Dictionary) -> void:
		signal_received = true
	
	EventBus.load_completed.connect(signal_handler)
	persistence_service.load_profile()
	
	await await_idle_frame()
	
	assert_bool(signal_received).is_true()
	EventBus.load_completed.disconnect(signal_handler)


func test_get_user_data_path_returns_valid_path() -> void:
	var path: String = persistence_service.get_user_data_path()
	
	assert_str(path).is_not_empty()
