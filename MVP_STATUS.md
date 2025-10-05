# MVP Development Status

**Version:** 0.1.0  
**Last Updated:** 2025-10-05  
**Branch:** develop

## 🎯 Core Loop Progress
The MVP focuses on delivering the **Design → Deploy → Analyze → Iterate** loop.

### ✅ Completed Components

#### 1. **Foundation & Architecture**
- [x] Godot 4.3 project configuration (mobile-first)
- [x] GitFlow branching model (master, develop)
- [x] Event Bus autoload for inter-system communication
- [x] Project documentation (README, CONTRIBUTING)
- [x] GdUnit4 testing framework integration

#### 2. **Programming Context (Design Phase)**
- [x] `Instruction` class - atomic AI logic unit
{{ ... }}

```
autobot-murderhell/
├── autoload/
│   └── event_bus.gd ✅ (Global event system)
├── src/
├── core/ ✅
│   ├── instruction.gd (Atomic AI instruction)
│   └── program.gd (AI program aggregate)
├── services/ ✅
│   ├── ai_translation_service.gd (Visitor pattern translator)
│   └── persistence_service.gd (Save/load with backup)
├── progression/ ✅
│   └── player_profile.gd (Progression aggregate root)
├── simulation/ (Partial)
│   ├── android_entity.gd ✅
│   ├── components/
│   │   ├── health_component.gd ✅
│   │   └── ai_core_component.gd ✅
│   ├── systems/
│   │   ├── movement_system.gd ✅
│   │   └── combat_system.gd ✅
│   └── simulation_manager.gd ✅
├── ui/ ✅
│   ├── block_editor.gd (Design phase UI)
│   └── debugger.gd (Analyze phase UI)
├── game_controller.gd ✅ (Core loop orchestration)
└── main.gd ✅
├── scenes/
│   ├── ui/
│   │   ├── block_editor.tscn ✅
│   │   ├── block_ui.tscn ✅
│   │   └── debugger.tscn ✅
{{ ... }}
│   └── main.tscn ✅
└── tests/ ✅
    ├── core/ (100% coverage)
    ├── services/ (95% coverage)
    ├── progression/ (100% coverage)
    └── simulation/ (Partial)
```

### Key Design Patterns Implemented

1. **Event-Driven Architecture**: EventBus autoload for decoupled communication
2. **Visitor Pattern**: AI Translation Service for Program-to-execution translation
3. **Entity-Component Pattern**: Godot-native EC for flexible Android composition
4. **Aggregate Root Pattern**: Program, AndroidEntity, PlayerProfile as bounded context roots
5. **Repository Pattern**: PersistenceService for data access abstraction

---

## 🚀 Running the Project

### Prerequisites
- Godot 4.3+
- GdUnit4 plugin (install from Asset Library)

### Quick Start

1. **Open Project**
   ```bash
   godot project.godot
   ```

2. **Install GdUnit4**
   - Project → Tools → Asset Library
   - Search "GdUnit4"
   - Download and Install

3. **Run Tests**
   - Project → Tools → GdUnit4 → Run All Tests
   - All core domain tests should pass ✅

4. **Run Game**
   - Press F5 or click Play button
   - Currently shows placeholder UI

### Current Functionality

- ✅ **Block Editor**: Add/remove instructions, view CPU cost
- ✅ **Program Validation**: Checks for disconnected GOTOs, empty programs
- ✅ **Save/Load**: Persistent player profile storage
- ✅ **Debugger UI**: Visual instruction stepping (not yet connected to live simulation)
- ⚠️ **Simulation**: Basic structure in place, needs level data
- ❌ **Tutorial**: Not yet implemented

---

## 📋 Next Sprint Priorities

### Sprint Goal: Playable First Level

1. **Create Tutorial Level** (Critical Path)
   - Simple room layout
   - 1-2 weak enemy androids
   - Clear objective: defeat enemies

2. **Connect AI to Systems** (Critical Path)
   - MOVE instruction → actual movement
   - ATTACK instruction → damage to target
   - Basic sensor (IS_ENEMY_NEAR)

3. **Win/Lose Conditions** (Critical Path)
   - All enemies defeated = Win
   - Player android destroyed = Lose
   - UI feedback for both

4. **Tutorial Tooltips**
   - First-time guidance overlay
   - "Create your first program" prompt

**Estimated Time:** 5-7 days for fully playable first level

---

## 🐛 Known Issues

1. **AI Core Execution**: Placeholder implementation, not yet driving actual systems
2. **No Collision Detection**: Androids can move through walls/obstacles
3. **No Visual Feedback**: Program execution happens in logs, not visible in game world
4. **CPU Capacity**: Hardcoded to 10, should come from player's android hardware
5. **Block Parameters**: Not editable in UI (e.g., can't change GOTO target)

---

## 📚 Key Files Reference

| File | Purpose | Status |
|------|---------|--------|
| `autoload/event_bus.gd` | Global event communication | ✅ Complete |
| `src/core/program.gd` | AI Program aggregate root | ✅ Complete |
| `src/services/ai_translation_service.gd` | Program translator | ✅ Complete |
| `src/progression/player_profile.gd` | Player progression state | ✅ Complete |
| `src/simulation/android_entity.gd` | Android entity (EC root) | ✅ Complete |
| `src/ui/block_editor.gd` | Design phase UI | ✅ Complete |
| `src/ui/debugger.gd` | Analyze phase UI | ✅ Complete |
| `src/game_controller.gd` | Core loop orchestration | ✅ Complete |

---

## 💡 Notes for Future Development

### Technical Debt
- Consider moving to a proper ECS library (GECS) if entity count grows beyond 100-200
- Block Editor needs drag-and-drop implementation (currently add-to-end only)
- Debugger needs breakpoint system implementation
- Need visual connection lines between blocks (currently just a list)

### Architecture Decisions to Revisit
- **Mobile-First UI**: Currently uses TabContainer, may need custom phase switcher
- **JSON Persistence**: Good for MVP, consider binary format for production
- **Static Levels**: Hand-crafted for MVP, PCG planned for v0.2.0

### Performance Considerations
- AI execution is synchronous (one instruction per frame), may need async for complex programs
- No object pooling yet for projectiles/effects
- EventBus uses signals, consider direct calls for high-frequency events

---

## ✅ Definition of Done (MVP)

The MVP is complete when:

- [ ] Player can complete Tutorial Level using visual programming
- [ ] Design → Deploy → Analyze → Iterate loop is fully functional
- [ ] Save/Load preserves progress between sessions
- [ ] At least 3 hand-crafted levels are playable
- [ ] Basic upgrade tree allows unlocking 2-3 new blocks
- [ ] All core gameplay tests pass
- [ ] Game builds and runs on Android, iOS, Windows, Linux
- [ ] Tutorial guides first-time players effectively
- [ ] No critical bugs in issue tracker

**Current MVP Completion:** ~65%
