## Unit tests for HealthComponent.
extends GdUnitTestSuite


func test_health_component_initialization() -> void:
	var health: HealthComponent = HealthComponent.new()
	
	# Default values before _ready()
	assert_float(health.max_health).is_equal(100.0)
	assert_float(health.armor).is_equal(0.0)
	assert_bool(health.is_alive).is_true()


func test_health_initialized_to_max_on_ready() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	
	await await_idle_frame()
	
	assert_float(health.current_health).is_equal(health.max_health)


func test_take_damage_reduces_health() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	var damage_dealt: float = health.take_damage(30.0)
	
	assert_float(damage_dealt).is_equal(30.0)
	assert_float(health.current_health).is_equal(70.0)


func test_take_damage_with_armor_reduces_damage() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.armor = 50.0  # 50% damage reduction
	add_child(health)
	await await_idle_frame()
	
	var damage_dealt: float = health.take_damage(100.0)
	
	# 50 armor = 50% reduction, so 100 damage -> 50 actual
	assert_float(damage_dealt).is_equal(50.0)
	assert_float(health.current_health).is_equal(50.0)


func test_take_damage_armor_caps_at_75_percent() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.armor = 100.0  # Would be 100% but capped at 75%
	add_child(health)
	await await_idle_frame()
	
	var damage_dealt: float = health.take_damage(100.0)
	
	# Max 75% reduction, so 100 damage -> 25 actual
	assert_float(damage_dealt).is_equal(25.0)
	assert_float(health.current_health).is_equal(75.0)


func test_take_damage_to_zero_marks_not_alive() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(150.0)  # More than max health
	
	assert_float(health.current_health).is_equal(0.0)
	assert_bool(health.is_alive).is_false()


func test_take_damage_when_dead_does_nothing() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(100.0)  # Kill it
	var damage_dealt: float = health.take_damage(50.0)  # Try again
	
	assert_float(damage_dealt).is_equal(0.0)
	assert_float(health.current_health).is_equal(0.0)


func test_heal_increases_health() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(50.0)
	health.heal(30.0)
	
	assert_float(health.current_health).is_equal(80.0)


func test_heal_cannot_exceed_max_health() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(20.0)
	health.heal(50.0)  # Heal more than needed
	
	assert_float(health.current_health).is_equal(health.max_health)


func test_heal_when_dead_does_nothing() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(100.0)  # Kill it
	health.heal(50.0)
	
	assert_float(health.current_health).is_equal(0.0)
	assert_bool(health.is_alive).is_false()


func test_get_health_percentage() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.max_health = 100.0
	add_child(health)
	await await_idle_frame()
	
	health.current_health = 75.0
	
	assert_float(health.get_health_percentage()).is_equal(0.75)


func test_is_health_low_default_threshold() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.current_health = 20.0  # 20% of 100
	
	assert_bool(health.is_health_low()).is_true()


func test_is_health_low_custom_threshold() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.current_health = 60.0
	
	assert_bool(health.is_health_low(0.5)).is_false()
	assert_bool(health.is_health_low(0.7)).is_true()


func test_reset_restores_to_max() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	await await_idle_frame()
	
	health.take_damage(100.0)  # Kill it
	health.reset()
	
	assert_float(health.current_health).is_equal(health.max_health)
	assert_bool(health.is_alive).is_true()
