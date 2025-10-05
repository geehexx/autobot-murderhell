# Autobot Murderhell

**Version:** 0.1.0 (MVP)  
**Engine:** Godot 4.3+

## Overview

A single-player, isometric dungeon crawler where players program their android's AI using a visual block-based editor. The core gameplay loop is: **Design → Deploy → Analyze → Iterate**.

## Project Structure

```
autobot-murderhell/
├── addons/                  # Godot plugins (e.g., GdUnit4)
├── dist/                    # Export artifacts (ignored in VCS)
├── docs/
│   ├── adr/                # Architecture Decision Records
│   └── design/             # High-level design documents
├── src/                     # Feature-based Godot content
│   ├── autoload/           # Global singletons (e.g., EventBus)
│   ├── core/               # Core domain logic (programs, instructions)
│   ├── progression/        # Player progression systems
│   ├── services/           # Cross-cutting services (AI translation, persistence)
│   ├── simulation/         # Simulation systems, components, and levels
│   └── ui/                 # UI scenes and scripts
├── tests/                   # GdUnit4 suites mirroring `src/`
│   ├── core/
│   ├── progression/
│   ├── services/
│   ├── simulation/
│   └── ui/
└── project.godot            # Godot project configuration
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

### GDScript Formatting & Linting

This project uses [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) for automated formatting and linting. All configuration lives in `pyproject.toml` and serves as the single source of truth for code style.

1. Install gdtoolkit (requires Python 3.9+):
   ```bash
   pip install godot-gdscript-toolkit
   ```
2. Format the entire repository:
   ```bash
   gdformat .
   ```
3. Run lint checks:
   ```bash
   gdlint .
   ```

Run these commands before committing to keep the tree compliant with project standards.

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
