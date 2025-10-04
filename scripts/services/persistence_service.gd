## Persistence Service
## Handles saving and loading PlayerProfile data to/from disk.
## Uses JSON format for human-readable, debuggable save files.
class_name PersistenceService
extends Node


## Save file path
const SAVE_FILE_PATH: String = "user://player_profile.save"

## Backup save file path (for safety)
const BACKUP_FILE_PATH: String = "user://player_profile.backup"


## Saves player profile data to disk.
## Returns true if successful, false otherwise.
func save_profile(profile_data: Dictionary) -> bool:
	print("[PersistenceService] Saving player profile...")
	
	# Validate profile data
	if not _validate_profile_data(profile_data):
		push_error("[PersistenceService] Invalid profile data")
		EventBus.save_completed.emit(false)
		return false
	
	# Create backup of existing save file if it exists
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.copy_absolute(SAVE_FILE_PATH, BACKUP_FILE_PATH)
		print("[PersistenceService] Backup created")
	
	# Open file for writing
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[PersistenceService] Failed to open save file: %s" % FileAccess.get_open_error())
		EventBus.save_completed.emit(false)
		return false
	
	# Convert to JSON and write
	var json_string: String = JSON.stringify(profile_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("[PersistenceService] Profile saved successfully to: %s" % SAVE_FILE_PATH)
	EventBus.save_completed.emit(true)
	return true


## Loads player profile data from disk.
## Returns a Dictionary with 'success' and 'data' keys.
func load_profile() -> Dictionary:
	print("[PersistenceService] Loading player profile...")
	
	# Check if save file exists
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[PersistenceService] No save file found, returning default profile")
		var default_profile: Dictionary = _create_default_profile()
		EventBus.load_completed.emit(true, default_profile)
		return {"success": true, "data": default_profile}
	
	# Open file for reading
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("[PersistenceService] Failed to open save file: %s" % FileAccess.get_open_error())
		
		# Try backup file
		return _try_load_backup()
	
	# Read and parse JSON
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[PersistenceService] JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return _try_load_backup()
	
	var profile_data: Dictionary = json.data
	
	# Validate loaded data
	if not _validate_profile_data(profile_data):
		push_error("[PersistenceService] Loaded profile data is invalid")
		return _try_load_backup()
	
	print("[PersistenceService] Profile loaded successfully")
	EventBus.load_completed.emit(true, profile_data)
	return {"success": true, "data": profile_data}


## Attempts to load from backup file.
func _try_load_backup() -> Dictionary:
	print("[PersistenceService] Attempting to load backup...")
	
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		print("[PersistenceService] No backup found, returning default profile")
		var default_profile: Dictionary = _create_default_profile()
		EventBus.load_completed.emit(true, default_profile)
		return {"success": true, "data": default_profile}
	
	var file: FileAccess = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("[PersistenceService] Failed to open backup file")
		var default_profile: Dictionary = _create_default_profile()
		EventBus.load_completed.emit(false, default_profile)
		return {"success": false, "data": default_profile}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[PersistenceService] Backup file also corrupted")
		var default_profile: Dictionary = _create_default_profile()
		EventBus.load_completed.emit(false, default_profile)
		return {"success": false, "data": default_profile}
	
	print("[PersistenceService] Backup loaded successfully")
	EventBus.load_completed.emit(true, json.data)
	return {"success": true, "data": json.data}


## Validates profile data structure.
func _validate_profile_data(data: Dictionary) -> bool:
	# Check required keys
	if not data.has("version"):
		return false
	if not data.has("player_name"):
		return false
	if not data.has("resources"):
		return false
	if not data.has("unlocked_blocks"):
		return false
	if not data.has("unlocked_chips"):
		return false
	if not data.has("upgrade_tree_state"):
		return false
	
	return true


## Creates a default player profile.
func _create_default_profile() -> Dictionary:
	return {
		"version": "0.1.0",
		"player_name": "Player",
		"resources": {
			"credits": 0,
			"data_shards": 0
		},
		"unlocked_blocks": [
			"MOVE",
			"GOTO",
			"LABEL"
		],
		"unlocked_chips": [],
		"upgrade_tree_state": {},
		"current_level": 1,
		"levels_completed": [],
		"statistics": {
			"total_runs": 0,
			"successful_runs": 0,
			"total_playtime_seconds": 0
		}
	}


## Deletes the save file (for testing or reset purposes).
func delete_save_file() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[PersistenceService] Save file deleted")
	
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		DirAccess.remove_absolute(BACKUP_FILE_PATH)
		print("[PersistenceService] Backup file deleted")
	
	return true


## Returns the user data directory path.
func get_user_data_path() -> String:
	return OS.get_user_data_dir()
