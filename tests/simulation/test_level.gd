## Unit tests for Level class.
extends GdUnitTestSuite


func test_level_initialization() -> void:
	var level: Level = auto_free(Level.new())
	level.level_id = "test_level"
	level.level_name = "Test Level"
	add_child(level)
	
	await await_idle_frame()
	
	assert_str(level.level_id).is_equal("test_level")
	assert_str(level.level_name).is_equal("Test Level")
	assert_bool(level.is_active).is_false()


func test_start_level_activates() -> void:
	var level: Level = auto_free(Level.new())
	add_child(level)
	await await_idle_frame()
	
	var player: AndroidEntity = auto_free(AndroidEntity.new())
	add_child(player)
	
	level.start_level(player)
	
	assert_bool(level.is_active).is_true()
	assert_object(level.player_android).is_equal(player)
	assert_float(level.elapsed_time).is_equal(0.0)


func test_start_level_positions_player_at_spawn() -> void:
	var level: Level = auto_free(Level.new())
	level.player_spawn_position = Vector2(200, 300)
	add_child(level)
	await await_idle_frame()
	
	var player: AndroidEntity = auto_free(AndroidEntity.new())
	add_child(player)
	
	level.start_level(player)
	
	assert_vector(player.position).is_equal(Vector2(200, 300))


func test_defeat_all_enemies_win_condition() -> void:
	var level: Level = auto_free(Level.new())
	level.win_condition = Level.WinCondition.DEFEAT_ALL_ENEMIES
	add_child(level)
	await await_idle_frame()
	
	var player: AndroidEntity = auto_free(AndroidEntity.new())
	player.add_to_group("androids")
	add_child(player)
	
	# Create enemy
	var enemy: AndroidEntity = auto_free(AndroidEntity.new())
	enemy.faction = "enemy"
	enemy.add_to_group("androids")
	add_child(enemy)
	await await_idle_frame()
	
	level.start_level(player)
	
	# Initially not won
	assert_int(level.get_living_enemy_count()).is_equal(1)
	
	# Kill enemy
	enemy.take_damage(1000.0)
	await await_idle_frame()
	
	# Process one frame to check win condition
	level._process(0.016)
	
	assert_bool(level.is_active).is_false()


func test_time_limit_lose_condition() -> void:
	var level: Level = auto_free(Level.new())
	level.time_limit = 1.0  # 1 second limit
	add_child(level)
	await await_idle_frame()
	
	var player: AndroidEntity = auto_free(AndroidEntity.new())
	add_child(player)
	
	level.start_level(player)
	
	# Simulate time passing
	level._process(1.5)  # Exceed time limit
	
	assert_bool(level.is_active).is_false()


func test_get_living_enemy_count() -> void:
	var level: Level = auto_free(Level.new())
	add_child(level)
	await await_idle_frame()
	
	var player: AndroidEntity = auto_free(AndroidEntity.new())
	player.add_to_group("androids")
	add_child(player)
	
	# Create two enemies
	var enemy1: AndroidEntity = auto_free(AndroidEntity.new())
	enemy1.faction = "enemy"
	enemy1.add_to_group("androids")
	add_child(enemy1)
	
	var enemy2: AndroidEntity = auto_free(AndroidEntity.new())
	enemy2.faction = "enemy"
	enemy2.add_to_group("androids")
	add_child(enemy2)
	
	await await_idle_frame()
	
	level.start_level(player)
	
	assert_int(level.get_living_enemy_count()).is_equal(2)
	
	# Kill one
	enemy1.take_damage(1000.0)
	await await_idle_frame()
	
	assert_int(level.get_living_enemy_count()).is_equal(1)
