# ADR-004: Feature-Based Directory Structure

**Status:** Accepted  \
**Date:** 2025-10-07  \
**Deciders:** Development Team

## Context

The original Godot project layout separated assets by technical type (`scripts/`, `scenes/`, `tests/`), forcing engineers to navigate across distant folders to understand a single gameplay feature. This fragmentation slowed debugging, documentation, and onboarding, especially once ADR-003 introduced a standardized low-level instruction set that touches UI, services, simulation, and progression subsystems.

Operational issues observed prior to this ADR:

- High cognitive load when tracing behavior across multiple top-level directories.
- Duplicate or stale documentation references to legacy paths (e.g., `scripts/ai/`).
- Difficulty coordinating refactors because features lacked clear ownership boundaries.
- Tests diverging from runtime code due to folder-level drift.

We evaluated three structure options:

1. Continue maintaining asset-type folders with beefed-up documentation.
2. Hybrid layout (feature folders for scripts only, keeping scenes/tests global).
3. Fully feature-based structure with co-located scripts, scenes, and tests beneath `src/` and `tests/`.

## Decision

Adopt a feature-based directory structure rooted at `src/` that groups all domain code, resources, and UI assets by bounded context. Core examples:

- `src/core/` for shared domain primitives such as `program.gd` and `instruction.gd`.
- `src/services/` for application services (e.g., `ai_translation_service.gd`, `persistence_service.gd`).
- `src/ui/` for presentation logic including the `block_editor` ADR-003-compliant tooling.
- `src/progression/`, `src/simulation/`, and other feature directories as needed.

Tests under `tests/` mirror the feature boundaries to keep validation adjacent to the code they exercise. Documentation and tooling references now point to ADR-003 instruction definitions rather than deprecated opcode names.

## Consequences

### Positive

- **Improved cohesion:** Feature teams can work within a single subtree with minimal cross-directory jumping.
- **Documentation alignment:** ADR-002 (Preload Pattern) and ADR-003 (Low-Level Instruction Set) references map directly to current paths, reducing drift.
- **Onboarding speed:** New contributors can explore a feature end-to-end without prior tribal knowledge of historical folders.
- **Refactor safety:** Co-located tests lower the chance of missing updates during instruction or EventBus changes.

### Negative

- **Migration cost:** Required a one-time bulk move of assets and updates to documentation, import paths, and CI scripts.
- **Tooling updates:** Build scripts, editor favorites, and external references (e.g., wiki links) needed a synchronized refresh.

### Neutral

- **Godot conventions:** While Godot tolerates both patterns, this ADR formalizes feature-first organization for future code.
- **Repository scale:** Additional directories (e.g., `src/tutorial/`) will be added as features mature, but the structure remains predictable.

## Implementation

- Migration executed Oct 05-06, 2025 in commit `refactor: migrate project structure to src layout`.
- Unit 2 (`feat: align ai instruction set with adr-003`) verified ADR-003 instruction usage across the new structure.
- Documentation, tooling, and tests are being updated in Unit 3 to reference ADR-003-compliant paths and workflows.

## References

- `docs/adr/ADR-001-GitFlow-Branching-Model.md` — branching strategy for coordinating feature work.
- `docs/adr/ADR-002-Preload-Pattern.md` — dependency resolution approach used across feature directories.
- `docs/adr/ADR-003-low_level_instruction_set.md` — authoritative instruction definitions consumed by UI and services.
- `docs/AITranslationService_EventBus_Recovery_Plan.md` — ongoing recovery plan tracking multi-unit progress.
