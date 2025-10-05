# ADR-001: GitFlow Branching Model

**Status:** Accepted  
**Date:** 2025-10-05  
**Deciders:** Development Team

## Context

The Autobot Murderhell project requires a robust branching strategy to support:
- Multiple developers working in parallel
- Clear separation between development and production-ready code
- Ability to prepare releases with final testing phases
- Quick response to critical production bugs
- Clean history for version management

The team evaluated several Git workflow models:
1. **GitHub Flow** - Simple, single `main` branch with feature branches
2. **GitFlow** - Structured with `main`, `develop`, feature, release, and hotfix branches
3. **Trunk-Based Development** - Frequent commits to a single trunk branch

## Decision

We will use the **GitFlow branching model** with the following structure:

- **`main`**: Production-ready code only. Tagged with version numbers (e.g., v0.1.0, v1.0.0)
- **`develop`**: Integration branch for ongoing development. All feature branches merge here
- **`feature/*`**: Created from `develop` for new features (e.g., `feature/tutorial-system`)
- **`release/*`**: Created from `develop` for release preparation and final testing
- **`hotfix/*`**: Created from `main` for critical production bug fixes

### Workflow Rules

1. All feature branches must be merged to `develop` via Pull Request
2. All PRs require at least one approval before merging
3. `main` only receives merges from `release/*` or `hotfix/*` branches
4. Release branches are created from `develop` when preparing a new version
5. Hotfix branches are the only exception to merge directly to `main`

## Consequences

### Positive

- **Clear separation of concerns**: Development (`develop`) vs production (`main`) code
- **Parallel development**: Multiple features can be developed simultaneously without conflicts
- **Release preparation**: Dedicated `release/*` branches allow final testing without blocking new development
- **Emergency response**: `hotfix/*` branches enable quick fixes to production issues
- **Clean version history**: Tags on `main` provide clear version markers

### Negative

- **Complexity**: More branches to manage than simpler models like GitHub Flow
- **Learning curve**: Team members must understand the GitFlow model
- **Merge overhead**: More merge points require attention to avoid conflicts

### Neutral

- **Branch lifetime**: Feature branches should be short-lived (1-3 days max) to avoid drift
- **CI/CD integration**: Automated testing runs on `develop` and release branches
- **Documentation**: The `CONTRIBUTING.md` guide provides clear instructions for contributors

## Implementation Notes

### Creating a Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature-name
# ... work and commit ...
git push -u origin feature/my-feature-name
# Create PR on GitHub targeting 'develop'
```

### Creating a Release Branch

```bash
git checkout develop
git pull origin develop
git checkout -b release/v0.2.0
# ... final testing and bug fixes ...
git checkout main
git merge --no-ff release/v0.2.0
git tag v0.2.0
git push origin main --tags
git checkout develop
git merge --no-ff release/v0.2.0
git push origin develop
```

### Creating a Hotfix Branch

```bash
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug
# ... fix the bug ...
git checkout main
git merge --no-ff hotfix/critical-bug
git tag v0.1.1
git push origin main --tags
git checkout develop
git merge --no-ff hotfix/critical-bug
git push origin develop
```

## References

- [GitFlow Model](https://nvie.com/posts/a-successful-git-branching-model/) by Vincent Driessen
- [Atlassian GitFlow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- `CONTRIBUTING.md` - Developer guide with GitFlow instructions
