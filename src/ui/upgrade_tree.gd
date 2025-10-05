## UpgradeTree - UI for the progression/upgrade system.
## Displays available upgrades and allows purchase with resources.
extends Control

## Preload required scripts
const PlayerProfileScript = preload("res://src/progression/player_profile.gd")

## Reference to player profile
var player_profile = null

## UI containers
var credits_label: Label
var data_shards_label: Label
var upgrade_list: VBoxContainer
var notification_label: Label

## Upgrade button references
var upgrade_buttons: Dictionary = {}


func _ready() -> void:
	_create_ui()
	EventBus.profile_updated.connect(_on_profile_updated)
	print("[UpgradeTree] Initialized")


## Creates the upgrade tree UI
func _create_ui() -> void:
	# Main layout
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 20.0
	margin.offset_top = 20.0
	margin.offset_right = -20.0
	margin.offset_bottom = -20.0
	add_child(margin)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "MainVBox"
	margin.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "UPGRADE TREE"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Resource display
	var resources_hbox: HBoxContainer = HBoxContainer.new()
	resources_hbox.name = "ResourcesHBox"
	vbox.add_child(resources_hbox)
	
	credits_label = Label.new()
	credits_label.text = "Credits: 0"
	credits_label.add_theme_font_size_override("font_size", 20)
	resources_hbox.add_child(credits_label)
	
	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(50, 0)
	resources_hbox.add_child(spacer1)
	
	data_shards_label = Label.new()
	data_shards_label.text = "Data Shards: 0"
	data_shards_label.add_theme_font_size_override("font_size", 20)
	resources_hbox.add_child(data_shards_label)
	
	# Separator
	var separator1: HSeparator = HSeparator.new()
	vbox.add_child(separator1)
	
	# Upgrades section
	var upgrades_scroll: ScrollContainer = ScrollContainer.new()
	upgrades_scroll.name = "UpgradesScroll"
	upgrades_scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(upgrades_scroll)
	
	upgrade_list = VBoxContainer.new()
	upgrade_list.name = "UpgradeList"
	upgrades_scroll.add_child(upgrade_list)
	
	# Notification area
	notification_label = Label.new()
	notification_label.name = "NotificationLabel"
	notification_label.text = ""
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(notification_label)
	
	# Populate upgrades
	_populate_upgrades()


## Populates the upgrade list with available upgrades
func _populate_upgrades() -> void:
	# Clear existing buttons
	for child in upgrade_list.get_children():
		child.queue_free()
	upgrade_buttons.clear()
	
	if not player_profile:
		var no_profile: Label = Label.new()
		no_profile.text = "No player profile loaded"
		upgrade_list.add_child(no_profile)
		return
	
	# Get available upgrades from PlayerProfile
	var upgrades: Array = _get_upgrade_definitions()
	
	for upgrade_def in upgrades:
		_create_upgrade_button(upgrade_def)


## Returns upgrade definitions
func _get_upgrade_definitions() -> Array:
	# These should match the upgrades in PlayerProfile
	return [
		{
			"id": "cpu_boost_1",
			"name": "CPU Boost I",
			"description": "Increase CPU capacity by 5 (10 → 15)",
			"cost_credits": 500,
			"cost_shards": 2,
			"unlocks": ["cpu_boost_2"]
		},
		{
			"id": "cpu_boost_2",
			"name": "CPU Boost II",
			"description": "Increase CPU capacity by 5 (15 → 20)",
			"cost_credits": 1000,
			"cost_shards": 4,
			"requires": ["cpu_boost_1"],
			"unlocks": ["cpu_boost_3"]
		},
		{
			"id": "memory_expansion_1",
			"name": "Memory Expansion I",
			"description": "Increase memory cells (4 → 8)",
			"cost_credits": 300,
			"cost_shards": 1,
			"unlocks": ["memory_expansion_2"]
		},
		{
			"id": "unlock_loop",
			"name": "Unlock LOOP Block",
			"description": "Unlocks LOOP instruction block",
			"cost_credits": 200,
			"cost_shards": 1,
			"unlocks": []
		},
		{
			"id": "unlock_condition",
			"name": "Unlock CONDITION Block",
			"description": "Unlocks CONDITION instruction block",
			"cost_credits": 400,
			"cost_shards": 2,
			"unlocks": []
		},
		{
			"id": "unlock_scan",
			"name": "Unlock SCAN Block",
			"description": "Unlocks SCAN sensor instruction",
			"cost_credits": 600,
			"cost_shards": 3,
			"unlocks": []
		}
	]


## Creates an upgrade button
func _create_upgrade_button(upgrade_def: Dictionary) -> void:
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	upgrade_list.add_child(panel)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.offset_left = 10.0
	hbox.offset_top = 10.0
	hbox.offset_right = -10.0
	hbox.offset_bottom = -10.0
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	panel.add_child(hbox)
	
	# Left side - upgrade info
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = upgrade_def["name"]
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)
	
	var desc_label: Label = Label.new()
	desc_label.text = upgrade_def["description"]
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(desc_label)
	
	var cost_label: Label = Label.new()
	cost_label.text = "Cost: %d Credits, %d Shards" % [
		upgrade_def["cost_credits"],
		upgrade_def["cost_shards"]
	]
	cost_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(cost_label)
	
	# Right side - purchase button
	var purchase_button: Button = Button.new()
	purchase_button.text = "Purchase"
	purchase_button.custom_minimum_size = Vector2(120, 0)
	purchase_button.pressed.connect(_on_purchase_button_pressed.bind(upgrade_def["id"]))
	hbox.add_child(purchase_button)
	
	# Store button reference
	upgrade_buttons[upgrade_def["id"]] = {
		"button": purchase_button,
		"panel": panel,
		"upgrade_def": upgrade_def
	}
	
	# Update button state
	_update_upgrade_button(upgrade_def["id"])


## Updates an upgrade button's state (enabled/disabled)
func _update_upgrade_button(upgrade_id: String) -> void:
	if not upgrade_buttons.has(upgrade_id):
		return
	
	var button_data: Dictionary = upgrade_buttons[upgrade_id]
	var button: Button = button_data["button"]
	var upgrade_def: Dictionary = button_data["upgrade_def"]
	
	if not player_profile:
		button.disabled = true
		button.text = "No Profile"
		return
	
	# Check if already purchased
	if player_profile.has_upgrade(upgrade_id):
		button.disabled = true
		button.text = "Purchased"
		button_data["panel"].modulate = Color(0.5, 0.8, 0.5, 0.7)
		return
	
	# Check if requirements are met
	var requires: Array = upgrade_def.get("requires", [])
	for req_id in requires:
		if not player_profile.has_upgrade(req_id):
			button.disabled = true
			button.text = "Locked"
			button_data["panel"].modulate = Color(0.5, 0.5, 0.5, 0.7)
			return
	
	# Check if player can afford it
	var can_afford: bool = (
		player_profile.credits >= upgrade_def["cost_credits"] and
		player_profile.data_shards >= upgrade_def["cost_shards"]
	)
	
	if can_afford:
		button.disabled = false
		button.text = "Purchase"
		button_data["panel"].modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		button.disabled = true
		button.text = "Can't Afford"
		button_data["panel"].modulate = Color(1.0, 1.0, 1.0, 0.5)


## Called when purchase button is pressed
func _on_purchase_button_pressed(upgrade_id: String) -> void:
	if not player_profile:
		_show_notification("Error: No player profile loaded", false)
		return
	
	if not upgrade_buttons.has(upgrade_id):
		return
	
	var upgrade_def: Dictionary = upgrade_buttons[upgrade_id]["upgrade_def"]
	
	# Attempt purchase
	var success: bool = player_profile.purchase_upgrade(
		upgrade_id,
		upgrade_def["cost_credits"],
		upgrade_def["cost_shards"]
	)
	
	if success:
		_show_notification("Purchased: %s" % upgrade_def["name"], true)
		_refresh_ui()
		EventBus.profile_updated.emit()
	else:
		_show_notification("Purchase failed: Insufficient resources", false)


## Shows a notification message
func _show_notification(message: String, is_success: bool) -> void:
	notification_label.text = message
	
	if is_success:
		notification_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	# Clear notification after 3 seconds
	await get_tree().create_timer(3.0).timeout
	notification_label.text = ""


## Sets the player profile
func set_player_profile(profile) -> void:
	player_profile = profile
	_refresh_ui()


## Refreshes the entire UI
func _refresh_ui() -> void:
	if not player_profile:
		return
	
	# Update resource display
	credits_label.text = "Credits: %d" % player_profile.credits
	data_shards_label.text = "Data Shards: %d" % player_profile.data_shards
	
	# Update all upgrade buttons
	for upgrade_id in upgrade_buttons.keys():
		_update_upgrade_button(upgrade_id)


## Called when profile is updated externally
func _on_profile_updated() -> void:
	_refresh_ui()
