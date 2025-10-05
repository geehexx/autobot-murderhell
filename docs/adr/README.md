# Architectural Decision Records (ADRs)

This directory contains records of significant architectural decisions made for the Autobot Murderhell project.

## What is an ADR?

An Architectural Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences. ADRs help:

- **Preserve context** - Future developers understand why decisions were made
- **Enable discussion** - Proposals can be reviewed before implementation
- **Track evolution** - See how the architecture has changed over time
- **Onboard new team members** - Quickly understand key technical choices

## When to Create an ADR

Create an ADR for decisions that:

- ✅ Affect the project structure or architecture
- ✅ Impact how developers write code (patterns, conventions)
- ✅ Introduce significant technical constraints
- ✅ Choose between multiple viable alternatives
- ✅ Have long-term consequences for the project

Do NOT create an ADR for:

- ❌ Minor implementation details
- ❌ Decisions that can be easily reversed
- ❌ Standard practices (unless deviating from them)

## How to Create an ADR

1. **Copy the template**:
   ```bash
   cp docs/adr/ADR-TEMPLATE.md docs/adr/ADR-XXX-short-title.md
   ```

2. **Number sequentially**: Use the next available ADR number (e.g., ADR-003, ADR-004)

3. **Use a descriptive title**: `ADR-XXX-Short-Descriptive-Title.md`

4. **Fill in all sections**:
   - **Status**: Start with "Proposed", change to "Accepted" when approved
   - **Context**: Explain the problem and constraints
   - **Decision**: State clearly what was decided
   - **Consequences**: List positive, negative, and neutral outcomes
   - **Implementation Notes**: Provide practical guidance for developers

5. **Create a Pull Request**: ADRs should be reviewed like code

6. **Update when superseded**: If a decision is replaced, update the status and link to the new ADR

## ADR Statuses

- **Proposed** - Under discussion, not yet implemented
- **Accepted** - Approved and should be followed
- **Deprecated** - No longer relevant but kept for historical context
- **Superseded** - Replaced by a newer ADR (link to the replacement)

## Current ADRs

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](ADR-001-GitFlow-Branching-Model.md) | GitFlow Branching Model | Accepted | 2025-10-05 |
| [ADR-002](ADR-002-Preload-Pattern.md) | Preload Pattern Instead of class_name | Accepted | 2025-10-05 |

## References

- [ADR GitHub Organization](https://adr.github.io/) - ADR best practices
- [Michael Nygard's ADR Article](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) - Original ADR concept
