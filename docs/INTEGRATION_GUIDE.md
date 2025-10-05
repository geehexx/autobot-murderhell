# Integration Guide: Tutorial System & Upgrade Tree

**Quick reference for integrating the new MVP features.**

---

## Tutorial System Integration

### Step 1: Add Required EventBus Signals

Add to `autoload/event_bus.gd`:

```gdscript
## Tutorial and progression signals
signal instruction_added(instruction: Dictionary)  # When player adds a block
signal profile_updated()  # When player profile changes
```

### Step 2: Update BlockEditor to Emit Signal

In `scripts/ui/block_editor.gd`, when adding an instruction:

```gdscript
func _on_add_block_button_pressed(block_type: String) -> void:
    # ... existing code to create instruction ...
    
    # Emit signal for tutorial system
    EventBus.instruction_added.emit({
        "type": block_type,
        "cpu_cost": instruction.cpu_cost,
        "parameters": instruction.parameters
    })
```

### Step 3: Add Tutorial System to Main Scene

In `scenes/main.tscn` or `scenes/game_scene.tscn`:

1. Add TutorialSystem as a child node (CanvasLayer type)
2. Attach script: `res://scripts/ui/tutorial_system.gd`
3. Position layer above other UI (layer value: 10)

Or via code in `scripts/main.gd`:

```gdscript
const TutorialSystemScript = preload("res://scripts/ui/tutorial_system.gd")

func _ready() -> void:
    var tutorial_system = TutorialSystemScript.new()
    tutorial_system.name = "TutorialSystem"
    tutorial_system.layer = 10
    add_child(tutorial_system)
    
    # Start tutorial for level 1
    if current_level_id == "level_1":
        tutorial_system.start_tutorial(current_level_id)
```

### Step 4: Connect to Level Start

In `scripts/game_controller.gd` or wherever levels start:

```gdscript
func _on_level_started(level_id: String) -> void:
    var tutorial_system = get_node("/root/Main/TutorialSystem")
    if tutorial_system and tutorial_system.should_show_tutorial(level_id):
        tutorial_system.start_tutorial(level_id)
```

---

## Upgrade Tree Integration

### Step 1: Create Upgrade Tree Tab

Option A: **Add to existing TabContainer**

In `scenes/main.tscn`:
1. Select the existing TabContainer
2. Add new tab: "Upgrades"
3. Add Control node as child
4. Attach script: `res://scripts/ui/upgrade_tree.gd`

Option B: **Create as separate scene**

1. Create `scenes/ui/upgrade_tree.tscn`
2. Root node: Control (anchor to full rect)
3. Attach script: `res://scripts/ui/upgrade_tree.gd`
4. Instance in main scene

### Step 2: Connect to PlayerProfile

In `scripts/game_controller.gd`:

```gdscript
func _setup_ui() -> void:
    # Existing code for block_editor...
    
    # Add upgrade tree setup
    var upgrade_tree: Control = get_node("UILayer/TabContainer/Upgrades/UpgradeTree")
    if upgrade_tree and upgrade_tree.has_method("set_player_profile"):
        upgrade_tree.set_player_profile(player_profile)
```

### Step 3: Update PlayerProfile to Emit Signal

In `scripts/progression/player_profile.gd`, after successful purchases:

```gdscript
func purchase_upgrade(upgrade_id: String, cost_credits: int, cost_shards: int) -> bool:
    # ... existing validation and purchase logic ...
    
    if purchase_successful:
        EventBus.profile_updated.emit()
        return true
    
    return false
```

### Step 4: Handle Resource Rewards

When player completes a level:

```gdscript
func _on_run_ended(result: Dictionary) -> void:
    if result["success"]:
        # Award resources based on performance
        var credits_earned: int = 100
        var shards_earned: int = 1
        
        player_profile.add_credits(credits_earned)
        player_profile.add_data_shards(shards_earned)
        
        EventBus.profile_updated.emit()
```

---

## Testing the Integration

### Manual Testing Checklist

**Tutorial System:**
- [ ] Tutorial starts automatically on level 1
- [ ] "Welcome" message displays correctly
- [ ] Clicking "Next" advances to "Explain Goal"
- [ ] Adding MOVE block triggers next tutorial step
- [ ] Adding ATTACK block triggers deploy step
- [ ] Deploying program triggers execution watching step
- [ ] Winning level triggers victory message
- [ ] Tutorial overlay dismisses when complete

**Upgrade Tree:**
- [ ] Displays current credits and data shards
- [ ] Shows all upgrade options
- [ ] "Locked" state for upgrades with unmet requirements
- [ ] "Can't Afford" state when resources insufficient
- [ ] "Purchase" button enabled when affordable
- [ ] Purchase deducts correct resources
- [ ] Purchased upgrades show "Purchased" state
- [ ] Visual feedback (panel color) matches state
- [ ] Notification displays on purchase success/failure

### Automated Testing (GdUnit4)

Create `tests/integration/test_tutorial_and_upgrades.gd`:

```gdscript
extends GdUnitTestSuite

const TutorialSystemScript = preload("res://scripts/ui/tutorial_system.gd")
const UpgradeTreeScript = preload("res://scripts/ui/upgrade_tree.gd")
const PlayerProfileScript = preload("res://scripts/progression/player_profile.gd")

func test_tutorial_full_flow():
    var tutorial = TutorialSystemScript.new()
    add_child(tutorial)
    
    tutorial.start_tutorial("level_1")
    assert_int(tutorial.current_state).is_equal(TutorialSystem.WELCOME)
    
    # Simulate user clicking through tutorial
    tutorial._on_next_button_pressed()
    tutorial._on_next_button_pressed()
    
    # Simulate adding blocks
    tutorial._on_instruction_added({"type": "MOVE"})
    assert_int(tutorial.current_state).is_equal(TutorialSystem.ADD_ATTACK_BLOCK)
    
    tutorial._on_instruction_added({"type": "ATTACK"})
    assert_int(tutorial.current_state).is_equal(TutorialSystem.DEPLOY_PROGRAM)
    
    tutorial.queue_free()

func test_upgrade_purchase_flow():
    var profile = PlayerProfileScript.new()
    profile.credits = 1000
    profile.data_shards = 5
    
    var tree = UpgradeTreeScript.new()
    add_child(tree)
    tree.set_player_profile(profile)
    
    # Simulate purchase
    tree._on_purchase_button_pressed("cpu_boost_1")
    
    # Verify purchase
    assert_bool(profile.has_upgrade("cpu_boost_1")).is_true()
    assert_int(profile.credits).is_equal(500)  # 1000 - 500
    assert_int(profile.data_shards).is_equal(3)  # 5 - 2
    
    tree.queue_free()
```

---

## Troubleshooting

### Tutorial Not Starting

**Symptom:** Tutorial overlay doesn't appear on level 1

**Fixes:**
1. Check that TutorialSystem node exists in scene tree
2. Verify `start_tutorial()` is being called
3. Check console for `[TutorialSystem] Initialized` message
4. Ensure `layer` property is set higher than other UI

### Upgrade Tree Not Updating

**Symptom:** Resource counts don't update after purchases

**Fixes:**
1. Verify `EventBus.profile_updated.emit()` is called after purchases
2. Check that upgrade tree is connected to profile
3. Call `upgrade_tree._refresh_ui()` manually to test
4. Check console for errors during purchase

### EventBus Signals Not Working

**Symptom:** Tutorial doesn't respond to player actions

**Fixes:**
1. Verify signals are defined in `autoload/event_bus.gd`
2. Check that emitters use `.emit()` not `.send()`
3. Ensure EventBus is in autoload list (Project Settings)
4. Use `EventBus.connect()` not `get_node("/root/EventBus").connect()`

---

## Code Examples

### Complete Tutorial Integration Example

```gdscript
# In scripts/game_controller.gd

const TutorialSystemScript = preload("res://scripts/ui/tutorial_system.gd")

var tutorial_system = null

func _ready() -> void:
    # ... existing initialization ...
    
    # Create tutorial system
    tutorial_system = TutorialSystemScript.new()
    tutorial_system.name = "TutorialSystem"
    tutorial_system.layer = 10
    add_child(tutorial_system)
    
    # Connect to level events
    EventBus.level_started.connect(_on_level_started)

func _on_level_started(level_id: String) -> void:
    if tutorial_system.should_show_tutorial(level_id):
        tutorial_system.start_tutorial(level_id)
```

### Complete Upgrade Tree Integration Example

```gdscript
# In scripts/game_controller.gd

const UpgradeTreeScript = preload("res://scripts/ui/upgrade_tree.gd")

var upgrade_tree = null

func _ready() -> void:
    # ... existing initialization ...
    
    # Setup upgrade tree
    upgrade_tree = get_node("UILayer/TabContainer/Upgrades/UpgradeTree")
    if upgrade_tree:
        upgrade_tree.set_player_profile(player_profile)

func _on_run_ended(result: Dictionary) -> void:
    if result["success"]:
        # Award resources
        player_profile.add_credits(100)
        player_profile.add_data_shards(1)
        EventBus.profile_updated.emit()
```

---

## Performance Considerations

### Tutorial System

- **Memory:** ~1 MB (UI nodes only)
- **CPU:** Minimal (event-driven)
- **Optimizations:**
  - Overlay hidden when not active (no rendering cost)
  - State transitions are instant
  - No polling or continuous checks

### Upgrade Tree

- **Memory:** ~500 KB (scrollable list)
- **CPU:** Low (only updates on profile changes)
- **Optimizations:**
  - Buttons only update on profile_updated signal
  - No frame-by-frame processing
  - Resource labels cached

Both systems are optimized for mobile deployment.

---

## Future Enhancements

### Tutorial System

- [ ] Multiple tutorial sequences for different levels
- [ ] Skippable tutorial (checkbox "Don't show again")
- [ ] Tutorial progress saved to PlayerProfile
- [ ] Animated highlight transitions
- [ ] Voice-over audio support
- [ ] Localization support

### Upgrade Tree

- [ ] Skill tree visualization (graph layout)
- [ ] Upgrade preview (show effects before purchase)
- [ ] Refund system (undo purchases)
- [ ] Unlock animations
- [ ] Upgrade categories/tabs
- [ ] Search/filter upgrades

---

## Related Documentation

- **ADR-001:** GitFlow branching for feature development
- **ADR-002:** Preload pattern usage in all scripts
- **CONTRIBUTING.md:** Code style and review guidelines
- **SETUP_TESTING.md:** Writing tests for UI components
- **MVP_STATUS.md:** Current implementation status

---

*Last updated: 2025-10-05*  
*For questions, see CONTRIBUTING.md or create a GitHub issue.*
