## Global Event Bus for decoupled inter-system communication.
## This singleton allows various game systems to communicate without direct references.
## Following the Autoload singleton pattern as specified in ADR-001.
extends Node


# Programming Context Events
## Emitted when the player modifies their AI Program in the Block Editor.
## @param program: The updated Program resource.
signal program_edited(program: Resource)

## Emitted when a Program needs to be validated before deployment.
## @param program: The Program to validate.
signal program_validation_requested(program: Resource)

## Emitted when Program validation is complete.
## @param is_valid: Whether the Program is valid.
## @param errors: Array of error messages (if any).
signal program_validation_completed(is_valid: bool, errors: Array)

## Emitted when the player requests to translate and deploy their Program.
## @param program: The Program to translate and execute.
signal translate_program_requested(program: Resource)

## Emitted when Program translation is complete.
## @param executable_script: The generated executable representation.
signal translation_completed(executable_script: Resource)


# Simulation Context Events
## Emitted when the player starts a new Run.
## @param level_id: The ID of the Level to load.
## @param program: The AI Program to execute.
signal run_started(level_id: String, program: Resource)

## Emitted when a Run ends (success, failure, or manual stop).
## @param result: Dictionary containing run results (success, stats, etc.).
signal run_ended(result: Dictionary)

## Emitted each simulation frame during a Run for debugging.
## @param instruction_index: The index of the currently executing Instruction.
## @param ai_state: Dictionary of the current AI state (variables, etc.).
signal instruction_executed(instruction_index: int, ai_state: Dictionary)

## Emitted when an Android takes damage.
## @param android: The Android entity.
## @param damage: Amount of damage taken.
## @param source: The damage source.
signal android_damaged(android: Node, damage: float, source: Node)

## Emitted when an Android is destroyed.
## @param android: The destroyed Android entity.
signal android_destroyed(android: Node)


# Progression Context Events
## Emitted when the player purchases an item from the Upgrade Tree.
## @param item_id: The ID of the purchased item.
signal upgrade_purchased(item_id: String)

## Emitted when a new Block, Chip, or capability is unlocked.
## @param unlock_type: Type of unlock ("block", "chip", "memory_cell", etc.).
## @param unlock_id: ID of the unlocked item.
signal capability_unlocked(unlock_type: String, unlock_id: String)

## Emitted when the player's resources (currency) change.
## @param resource_type: Type of resource ("credits", "data_shards", etc.).
## @param new_amount: The new resource amount.
signal resources_changed(resource_type: String, new_amount: int)


# Persistence Events
## Emitted to request saving the PlayerProfile.
signal save_requested()

## Emitted when save is complete.
## @param success: Whether the save was successful.
signal save_completed(success: bool)

## Emitted to request loading the PlayerProfile.
signal load_requested()

## Emitted when load is complete.
## @param success: Whether the load was successful.
## @param profile_data: The loaded profile data (if successful).
signal load_completed(success: bool, profile_data: Dictionary)


# Debug Context Events
## Emitted when the player pauses/resumes the simulation in the Debugger.
## @param is_paused: Whether the simulation should be paused.
signal debug_pause_toggled(is_paused: bool)

## Emitted when the player steps forward one instruction in the Debugger.
signal debug_step_requested()

## Emitted when the player sets a breakpoint.
## @param instruction_index: The instruction index to break at.
signal debug_breakpoint_set(instruction_index: int)

## Emitted when the player clears a breakpoint.
## @param instruction_index: The instruction index to clear.
signal debug_breakpoint_cleared(instruction_index: int)


# UI Events
## Emitted when the UI needs to be updated (generic).
## @param ui_context: String identifying which UI ("editor", "debugger", "upgrade_tree").
## @param data: Dictionary of data to update.
signal ui_update_requested(ui_context: String, data: Dictionary)


func _ready() -> void:
	print("[EventBus] Initialized and ready for inter-system communication.")
