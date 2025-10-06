# AITranslationService & EventBus Recovery Plan

## 1. Situation Overview

### Timeline

- Oct 5-6, 2025: Phase 1 refactor completed (src/ layout migration)
- Oct 6, 2025: Test migration and EventBus debugging attempted
- Current: Blocking test failures and incomplete deliverables

### Repository State

- ✓ Feature-based `src/` directory structure established
- ✓ Tests partially migrated to preload pattern
- ✓ GdUnit4 added via git submodule
- ✗ EventBus dependency injection failing in service tests
- ✗ Legacy instruction opcodes reintroduced (temporary workaround)
- ✗ Phase 1 documentation incomplete
- ✗ Phase 2-4 tasks not started

## 2. Key Problems

### P1: EventBus Dependency Injection (BLOCKING)

**File:**  `tests/services/test_ai_translation_service.gd`
**Issue:**  `test_translate_emits_event_on_success()` fails - signal never fires
**Root cause:** Override mechanism doesn't affect the instance calling `translate_program()`
**Status:** Requires DI implementation verification

### P2: Instruction Set Inconsistency

**Files:**  `src/core/instruction.gd`, multiple tests
**Issue:** Legacy opcodes (MOVE, ATTACK, GOTO) reintroduced during debugging
**Conflict:** Violates ADR-003 low-level instruction mandate
**Status:** Temporary; requires systematic replacement

### P3: Documentation Gaps

#### Missing

- `docs/adr/ADR-004-feature-based-structure.md`
- Updated `TESTING_RESULTS.md` with current test state
- Test procedures for Godot 4.5 in `SETUP_TESTING.md`

### P4: Tooling & Automation

#### Pending from original plan

- `pyproject.toml` for gdtoolkit configuration
- Expanded test coverage (tutorial system, AI core component)
- `.windsurf/rules/` directory with 3 rule files
- Consolidated CI workflow (`.github/workflows/main.yml`)

## 3. Validated Decisions

From user clarifications (Oct 6, 2025):

1. **Instruction Strategy:** Refactor to ADR-003 compliance; legacy opcodes are temporary only
2. **EventBus Override:** Prefer dependency injection; consider singletons only if DI fails
3. **Diagnostics:** Permanent logging acceptable for ongoing observability
4. **Cleanup:** Remove temporary conversation markdown files after implementation verified

## 4. Implementation Units

### Unit 1: EventBus Override Fix (PRIORITY 1)

#### Objective (Unit 1)

Resolve `test_translate_emits_event_on_success()` failure

#### Key Files (Unit 1)

- `src/services/ai_translation_service.gd`
- `tests/services/test_ai_translation_service.gd`

#### Approach (Unit 1)

1. Add permanent diagnostic logging in `translate_program()` showing EventBus source
2. Verify override is set on the same instance that translates
3. Ensure stub's `translation_completed` signal is properly connected

#### Validation (Unit 1)

```bash
/snap/bin/godot4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --path . --add tests/services/test_ai_translation_service.gd --ignoreHeadlessMode
```

**Expected**: All tests pass

#### Definition of Done (Unit 1)

- [ ] Test suite passes
- [ ] Diagnostic logs show correct EventBus source in both test and production
- [ ] Changes committed with message: `fix: resolve EventBus dependency injection in AITranslationService`

### Unit 2: ADR-003 Instruction Compliance

#### Objective (Unit 2)

Remove legacy opcodes and align with ADR-003 low-level instruction set

#### Key Files (Unit 2)

- `src/core/instruction.gd` (remove MOVE, ATTACK, GOTO, CONDITION, READ_SENSOR, WRITE_MEMORY, READ_MEMORY)
- `src/services/ai_translation_service.gd`
- `smoke_test.gd`
- `manual_verification.gd`
- `tests/core/test_instruction.gd`
- `tests/core/test_program.gd`

#### Reference (Unit 2)

`docs/adr/ADR-003-low_level_instruction_set.md` for compliant instruction set.

#### Validation (Unit 2)

```bash
# Run affected tests
/snap/bin/godot4 --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --path . --add tests/core/test_program.gd --ignoreHeadlessMode
/snap/bin/godot4 --headless --script smoke_test.gd --quit-timeout 5
```

#### Definition of Done (Unit 2)

- [ ] Legacy opcodes removed from `INSTRUCTION_DEFINITIONS`
- [ ] All consumers updated to use ADR-003 instructions
- [ ] Tests passing
- [ ] Changes committed: `refactor: align instruction set with ADR-003`

### Unit 3: Documentation Completion

#### Objective (Unit 3)

Close Phase 1 documentation gaps

#### Deliverables (Unit 3)

##### ADR-004 (`docs/adr/ADR-004-feature-based-structure.md`)

- Drafted Oct 7, 2025 capturing rationale, consequences, and references for the feature-based structure rollout.

```markdown
# ADR-004: Feature-Based Directory Structure

## Status

Accepted (Oct 2025)

## Context

Original project structure separated scripts/ and scenes/ by asset type, creating cross-references and reducing feature cohesion.

## Decision

Migrate to feature-based structure under src/ where each feature directory contains all related scripts, scenes, and assets.

## Consequences

### Positive

- Improved scalability and feature isolation
- Easier onboarding (related code co-located)
- Reduced circular dependencies

### Negative

- One-time migration effort
- Existing documentation required updates

## Implementation

Completed Oct 5-6, 2025 (commit: refactor: migrate project structure to src layout)
```

##### Updates to `TESTING_RESULTS.md` (Unit 3)

- Replaced Oct 5 snapshot with Oct 7 ADR-003 regression matrix, smoke snapshot, and forward-looking coverage tasks.

##### Updates to `SETUP_TESTING.md` (Unit 3)

- Documented Godot 4.5 prerequisites, ADR-003 regression matrix commands, and smoke workflow integration.

#### Validation (Unit 3)

```bash
grep -r "scripts/" docs/  # Should return minimal/no results
grep -r "scenes/" docs/  # Should return minimal/no results
```

#### Definition of Done (Unit 3)

- [x] ADR-004 exists and follows template
- [x] Test documentation reflects current state
- [ ] No stale path references in docs/
- [ ] Committed: `docs: complete Phase 1 documentation (ADR-004, test results)`

### Unit 4: Phase 2 Tooling Foundation

#### Objective (Unit 4)

Establish gdtoolkit configuration and test expansion scaffolding

##### Create `pyproject.toml`

```toml
[tool.gdformat]
max-line-length = 100

[tool.gdlint]
function-name = "_?[a-z_][a-z0-9_]*"
variable-name = "_?[a-z_][a-z0-9_]*"
signal-name = "[a-z_][a-z0-9_]*"
constant-name = "[A-Z_][A-Z0-9_]*"
max-file-lines = 1000
disable = ["class-name-missing-extend"]
```

##### Stub Test Files

###### `tests/ui/test_tutorial_system.gd`

```gdscript
extends GdUnitTestSuite

# Placeholder for tutorial system tests (Phase 2)
# TODO: Implement state transition tests with EventBus signals
```

###### `tests/simulation/test_ai_core_component.gd`

```gdscript
extends GdUnitTestSuite

# Placeholder for AI core component tests (Phase 2)
# TODO: Verify instruction execution and CPU budget enforcement
```

#### Validation (Unit 4)

```bash
gdformat --check .
gdlint .
```

#### Definition of Done (Unit 4)

- [ ] `pyproject.toml` exists at repo root
- [ ] No critical gdformat/gdlint violations
- [ ] Stub test files created
- [ ] Committed: `build: add pyproject.toml and stub Phase 2 tests`

## 5. Post-Implementation Cleanup

### After all units complete

1. Remove temporary files:
   - `Refactor Godot Project Documentation.md`
   - `Debug AITranslationService EventBus.md`
   - `AITranslationService EventBus Debug.md`

1. Verify clean state:

```bash
git status # Should show clean working tree
```

1. Archive or remove reports:
   - Consider adding `reports` to `.gitignore` permanently
   - Or document their purpose in `SETUP_TESTING.md`

## 6. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| EventBus DI implementation complex | High | Start with simplest DI pattern; escalate to static if needed |
| Instruction refactor breaks gameplay | High | Comprehensive test suite run before commit |
| Legacy code dependencies missed | Medium | Grep for opcode strings before declaring done |
| Token limit exceeded | Medium | Work in atomic units; commit frequently |

## 7. Success Criteria

### Must have

- All GdUnit4 tests passing
- ADR-004 documented
- Clean git status

### Should have

- pyproject.toml configured
- Stub tests for Phase 2
- Updated test documentation

### Could have

- Reports directory cleaned/documented
- Performance benchmarks for new instruction set

## 8. References

- Original plan: `Refactor Godot Project Documentation.md` (to be removed after implementation)
- Debug history: `Debug AITranslationService EventBus.md` (to be removed)
- Consolidated summary: `AITranslationService EventBus Debug.md` (to be removed)
- Godot 4.5 docs: [https://docs.godotengine.org/en/stable/](https://docs.godotengine.org/en/stable/)
- ADR-002: `docs/adr/ADR-002-Preload-Pattern.md`
- ADR-003: `docs/adr/ADR-003-low_level_instruction_set.md`
