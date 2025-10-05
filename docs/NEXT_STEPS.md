# Next Steps for MVP Completion

**Last Updated:** 2025-10-05  
**Current Status:** Phase 1 & 2 Complete, Phase 3 Partially Complete

---

## Immediate Actions Required

### 1. Install GdUnit4 Plugin (CRITICAL)

The testing framework must be installed before tests can run.

**Option A: Via Godot Editor (Recommended)**
```
1. Open project in Godot 4.3+
2. Click "AssetLib" tab at the top
3. Search for "GdUnit4"
4. Click "Download" → "Install"
5. Enable in Project → Project Settings → Plugins
```

**Option B: Manual Git Clone**
```bash
cd /home/gxx/projects/autobot-murderhell
mkdir -p addons
git clone https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
```

**Verification:**
```bash
godot-4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue
```

---

## Phase 3: Remaining MVP Features

### Priority 1: Integration & Testing

#### A. Integrate Tutorial System

**Tasks:**
1. Create scene file `src/ui/tutorial_overlay.tscn`
2. Add TutorialSystem to main game scene
3. Connect to level_1_tutorial.tscn
4. Add EventBus signals:
   - `instruction_added` (emit from BlockEditor)
   - `profile_updated` (emit from PlayerProfile)
5. Write GdUnit4 tests:
   ```bash
   tests/ui/test_tutorial_system.gd
   ```

**Test Example:**
```gdscript
extends GdUnitTestSuite

const TutorialSystemScript = preload("res://src/ui/tutorial_system.gd")

func test_tutorial_state_progression():
    var tutorial = TutorialSystemScript.new()
    add_child(tutorial)
    
    tutorial.start_tutorial("level_1")
    assert_int(tutorial.current_state).is_equal(TutorialSystem.WELCOME)
    
    tutorial._on_next_button_pressed()
    assert_int(tutorial.current_state).is_equal(TutorialSystem.EXPLAIN_GOAL)
```

#### B. Integrate Upgrade Tree

**Tasks:**
1. Create scene file `src/ui/upgrade_tree.tscn`
2. Add UpgradeTree tab to main UI
3. Connect to GameController's PlayerProfile
4. Wire up EventBus.profile_updated signal
5. Write GdUnit4 tests:
   ```bash
   tests/ui/test_upgrade_tree.gd
   ```

**Test Example:**
```gdscript
extends GdUnitTestSuite

const UpgradeTreeScript = preload("res://src/ui/upgrade_tree.gd")
const PlayerProfileScript = preload("res://src/progression/player_profile.gd")

func test_upgrade_purchase():
    var profile = PlayerProfileScript.new()
    profile.credits = 1000
    profile.data_shards = 5
    
    var tree = UpgradeTreeScript.new()
    tree.set_player_profile(profile)
    tree._on_purchase_button_pressed("cpu_boost_1")
    
    assert_bool(profile.has_upgrade("cpu_boost_1")).is_true()
    assert_int(profile.credits).is_equal(500)
    assert_int(profile.data_shards).is_equal(3)
```

### Priority 2: Visual Assets

**Current State:** Using ColorRect placeholders

**Tasks:**
1. **Android Sprites:**
   - Create/source simple 2D sprite (32x32 or 64x64)
   - Player android: Blue/cyan tint
   - Enemy android: Red/orange tint
   - Update `_add_android_visual()` in `src/simulation/simulation_manager.gd`

2. **UI Theme:**
   - Create `assets/themes/main_theme.tres`
   - Apply to UI scenes
   - Define colors for:
     - Primary: Cyan (#00d9ff)
     - Secondary: Purple (#8b5cf6)
     - Danger: Red (#ef4444)
     - Success: Green (#10b981)

3. **Block Icons:**
   - MOVE: Arrow icon
   - ATTACK: Crosshair icon
   - GOTO: Loop arrow
   - CONDITION: Diamond shape
   - LABEL: Flag/marker

**Reference:**
```gdscript
# Update in src/simulation/simulation_manager.gd
func _add_android_visual(android, color: Color) -> void:
    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = preload("res://assets/sprites/android.png")
    sprite.modulate = color
    android.add_child(sprite)
```

### Priority 3: Enhanced AI Execution

**Current State:** AI instructions execute but don't fully connect to systems

**Tasks:**
1. **Movement Integration:**
   - Ensure MOVE instruction updates android position
   - Add collision detection
   - Add movement animation

2. **Combat Integration:**
   - Ensure ATTACK instruction deals damage
   - Add attack range checking
   - Add damage numbers/feedback

3. **Sensor Integration:**
   - IS_ENEMY_NEAR sensor
   - READ_HEALTH sensor
   - SCAN for enemy detection

**File to Update:**
```
src/simulation/components/ai_core_component.gd
src/simulation/systems/movement_system.gd
src/simulation/systems/combat_system.gd
```

### Priority 4: Additional Levels

**Current State:** Only level_1_tutorial exists

**Tasks:**
1. Create `src/simulation/levels/level_2.tscn`
   - More enemies (3-4)
   - Obstacles/walls
   - Larger arena

2. Create `src/simulation/levels/level_3.tscn`
   - Multiple rooms
   - Enemy patrol patterns
   - Resource pickups

3. Update level selection UI

---

## Testing Strategy

### Refactor Existing Tests

All test files need updating to use preload pattern:

```bash
tests/core/test_program.gd
tests/core/test_instruction.gd
tests/services/test_ai_translation_service.gd
tests/services/test_persistence_service.gd
tests/progression/test_player_profile.gd
tests/simulation/test_health_component.gd
tests/ui/test_game_flow.gd
```

**Pattern to Apply:**
```gdscript
# OLD (will fail):
func test_example() -> void:
    var program: Program = Program.new()

# NEW (correct):
const ProgramScript = preload("res://src/core/program.gd")

func test_example() -> void:
    var program = ProgramScript.new()
```

### Write New Tests

**Required Test Files:**
- `tests/ui/test_tutorial_system.gd`
- `tests/ui/test_upgrade_tree.gd`
- `tests/simulation/test_movement_system.gd`
- `tests/simulation/test_combat_system.gd`
- `tests/simulation/test_ai_core_component.gd`
- `tests/ui/test_scene_based_gameplay.gd`

### Target Coverage

- Core logic: 100% ✅
- Services: 95% ✅
- Simulation systems: 80% (currently ~40%)
- UI components: 60% (currently ~0%)

---

## Performance Optimization (Phase 4)

### When to Optimize

Only after MVP features are complete and tested.

### Profiling Steps

1. Run Godot's built-in profiler: Debug → Profiler
2. Identify bottlenecks in:
   - Physics processing
   - Rendering (draw calls)
   - Script execution
   - Signal emissions

### Optimization Techniques

**Rendering:**
- Use `MultiMeshInstance2D` for repeated sprites (projectiles, particles)
- Reduce draw calls with texture atlases
- Cull off-screen entities

**GDScript:**
- Static typing already in place ✅
- Implement object pooling for frequently created/destroyed nodes
- Cache frequently accessed nodes

**Physics:**
- Use simplified collision shapes
- Reduce physics FPS if needed
- Use collision layers effectively

---

## EventBus Signals to Add

The new features require additional EventBus signals:

```gdscript
# In src/autoload/event_bus.gd

# Tutorial System
signal instruction_added(instruction: Dictionary)

# Upgrade Tree
signal profile_updated()

# Level System
signal level_completed(level_id: String, stats: Dictionary)
signal level_failed(level_id: String, reason: String)
```

**Integration Points:**

1. **BlockEditor** → Emit `instruction_added` when player adds a block
2. **PlayerProfile** → Emit `profile_updated` after purchases
3. **Level** → Emit `level_completed` and `level_failed` for progression

---

## Documentation Updates

### Files to Update

1. **MVP_STATUS.md**
   - Mark tutorial system as complete
   - Mark upgrade tree UI as complete
   - Update completion percentage (~70%)

2. **README.md**
   - Add Phase 1-3 completion status
   - Link to new documentation
   - Update quick start guide

3. **QUICK_REFERENCE.md**
   - Add tutorial system examples
   - Add upgrade tree usage
   - Update EventBus signal list

---

## Git Workflow

### Commit Strategy

Create separate commits for logical changes:

```bash
git add docs/adr/
git commit -m "docs(adr): add ADR framework and critical decisions

- Create ADR-001 for GitFlow branching model
- Create ADR-002 for preload pattern mandate
- Add ADR template for future decisions

See docs/adr/README.md for details"

git add .github/workflows/
git commit -m "ci: add GitHub Actions CI/CD pipelines

- Add godot-ci.yml for automated testing and builds
- Add code-quality.yml for preload pattern enforcement
- Configure multi-platform builds for release branches

Closes #[issue-number]"

git add scripts/ui/tutorial_system.gd
git commit -m "feat(tutorial): implement tutorial system with State Machine

- Create 9-state tutorial flow for level 1
- Add overlay UI with step-by-step guidance
- Integrate with EventBus for state transitions
- Follow State Machine pattern per architectural mandate

Refs: ADR-001, #[issue-number]"

git add scripts/ui/upgrade_tree.gd
git commit -m "feat(upgrades): implement upgrade tree UI

- Create scrollable upgrade list with purchase logic
- Add resource display (credits, data shards)
- Implement button states (purchased, locked, affordable)
- Integrate with PlayerProfile system

Refs: #[issue-number]"

git add CONTRIBUTING.md
git commit -m "docs(contributing): enhance with preload pattern mandate

- Add critical preload pattern requirement at top
- Expand GitFlow workflow documentation
- Add code review guidelines
- Document architectural patterns
- Include development environment setup

Refs: ADR-002"
```

### Pull Request

When ready to merge:

```bash
git push -u origin develop
```

Create PR on GitHub:
- **Title:** `feat(mvp): complete Phase 1-3 environment setup and core features`
- **Description:** Link to `docs/PHASE_1_2_COMPLETION_REPORT.md`
- **Reviewers:** Request at least one team member review

---

## Success Criteria

Phase 3 is complete when:

- ✅ Tutorial system integrated and tested
- ✅ Upgrade tree integrated and tested
- ✅ All existing tests refactored to preload pattern
- ✅ All tests passing (100% of implemented features)
- ✅ Visual assets in place (or acceptable placeholders)
- ✅ EventBus signals wired up
- ✅ Documentation updated

---

## Timeline Estimate

| Task | Estimated Time |
|------|---------------|
| Install GdUnit4 | 15 minutes |
| Refactor existing tests | 2 hours |
| Integrate tutorial system | 3 hours |
| Integrate upgrade tree | 2 hours |
| Write new tests | 3 hours |
| Visual assets (placeholders) | 1 hour |
| EventBus signal wiring | 1 hour |
| Documentation updates | 1 hour |
| **Total** | **~13 hours (2 work days)** |

---

## Questions & Support

- **ADR Process:** See `docs/adr/README.md`
- **Testing Setup:** See `docs/SETUP_TESTING.md`
- **Code Style:** See `CONTRIBUTING.md`
- **GitFlow:** See `docs/adr/ADR-001-GitFlow-Branching-Model.md`
- **Preload Pattern:** See `docs/adr/ADR-002-Preload-Pattern.md`

---

*Document created: 2025-10-05*  
*Next review: After GdUnit4 installation*
