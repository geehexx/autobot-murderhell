# Autobot Murderhell

**Version:** 0.1.0 (MVP)  
**Engine:** Godot 4.3+

## Overview

A single-player, isometric dungeon crawler where players program their android's AI using a visual block-based editor. The core gameplay loop is: **Design → Deploy → Analyze → Iterate**.

## Project Structure

```
autobot-murderhell/
├── autoload/          # Global singleton scripts (Event Bus)
├── scenes/            # Scene files (.tscn)
│   ├── ui/           # UI scenes (Block Editor, Debugger, Upgrade Tree)
│   ├── entities/     # Entity scenes (Android, Chips, etc.)
│   └── levels/       # Level scenes
├── scripts/           # GDScript source files
│   ├── core/         # Core domain entities (Programming Context)
│   ├── simulation/   # Simulation systems (Simulation Context)
│   ├── progression/  # Progression system (Progression Context)
│   └── services/     # Services (AI Translation, Persistence)
├── tests/             # GdUnit4 test files
├── assets/            # Game assets (sprites, sounds, etc.)
└── addons/            # Godot plugins (GdUnit4)
```

## Development Standards

- **Commit Format:** [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- **Branching Model:** [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)
- **Code Style:** [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html)
- **Testing:** TDD-first approach using [GdUnit4](https://github.com/MikeSchulze/gdUnit4)

## Getting Started

1. Install Godot 4.3 or later
2. Clone this repository
3. Open the project in Godot
4. Install GdUnit4 plugin from the Asset Library
5. Run tests: `Project → Tools → GdUnit4 → Run All Tests`

## Architecture

- **Architectural Style:** Modular, Event-Driven Architecture
- **Communication:** Global Event Bus (Autoload singleton)
- **Simulation:** Godot-native Entity-Component pattern

## Core Contexts

1. **Programming Context:** Block Editor, AI Program creation
2. **Simulation Context:** Game world, Android execution, combat
3. **Progression Context:** Upgrade Tree, player profile, persistence

## License

TBD
