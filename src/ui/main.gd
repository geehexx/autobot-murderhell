## Main entry point for Autobot Murderhell.
## Manages the high-level game flow and initialization.
extends Control


func _ready() -> void:
	print("[Main] Autobot Murderhell v0.1.0 initializing...")
	print("[Main] Mobile-first mode: ", DisplayServer.is_touchscreen_available())
	
	# Connect to EventBus to verify it's working
	if EventBus:
		print("[Main] EventBus connection verified")
	else:
		push_error("[Main] EventBus not found! Check autoload configuration.")
	
	# Future: Load player profile, show main menu, etc.
