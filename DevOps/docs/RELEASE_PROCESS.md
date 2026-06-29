# Release Process Guide

This document defines the step-by-step pipeline, branch promotion gates, build validation checks, and version tagging rules for the PMS Dashboard platform.

---

## 1. Release Lifecycle Stages

Features are promoted sequentially through the Git workspace branches:

```
[feature/...] ──(Merge Request)──> [develop] ──(Freeze)──> [release/vX.Y] ──(Validation)──> [main]
                                                                                              │
                                                                                        (Git Tag Created)
```

### Stage 1: Active Development
- Feature code is developed inside branches prefixed with `feature/`.
- Once code compiles locally, a pull request is opened targeting `develop`. Code reviews and automatic checks are executed before merge.

### Stage 2: Release Branch & Feature Freeze
- When features target milestone goals, create a release branch: `release/v2.1`.
- Feature freeze is declared: no new features are merged into this release branch.

### Stage 3: Quality Assurance & Validation
- Run tests: `python -m pytest tests -v`.
- Build bundles: `npm run build`.
- If issues are discovered, bugfixes are committed directly to `release/v2.1`.

### Stage 4: Production Deployment & Tagging
- Merge `release/v2.1` into `main`.
- Create a Git release tag:
  ```bash
  git tag -a v2.1-infrastructure -m "Infrastructure Hardening Enterprise Release v2.1"
  git push origin v2.1-infrastructure --tags
  ```
- Deploy application: `./scripts/deploy.sh` and verify `/api/health/readiness` state.

### Stage 5: Syncing Back
- Merge `release/v2.1` back into `develop` to sync bugfixes:
  ```bash
  git checkout develop
  git merge release/v2.1
  git push origin develop
  ```
- Delete the release branch locally and remotely.
