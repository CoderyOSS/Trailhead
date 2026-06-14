# Test File Locking — TDD Workflow Integrity

## Problem

In a multi-stage TDD workflow, tests are written and reviewed in one stage, then implemented against in the next. The implementation agent must not modify tests to make them pass — it must write code that satisfies the existing tests.

Every project has unique directory structure, so hardcoding test paths is fragile.

## Core Insight

The test-writing phase itself identifies which files to lock. Git tracks every change — no convention-based discovery needed.

## Mechanism: `chown root:root`

Agent runs as `gem` (uid 1000). Orchestration executes phases as `root`. This UID asymmetry is the security boundary — kernel enforces it.

### Workflow Stages

```
1. test-write    → agent (gem) writes tests, full write access
2. review        → human approves test commit
3. lock          → orchestration (root) locks test files
4. implement     → agent (gem) writes code, tests are read-only
5. validate      → git diff confirms no test files changed
6. unlock        → orchestration (root) restores ownership
```

### Lock Script

Runs as root. Takes a git commit SHA (the approved test commit) or a range.

```bash
#!/bin/bash
# lock-tests.sh — run as root
# Usage: lock-tests.sh <commit-or-range>
#
# Examples:
#   lock-tests.sh HEAD              # lock files changed in last commit
#   lock-tests.sh abc123..def456    # lock files changed in range

LOCK_REF="${1:-HEAD}"

mapfile -t FILES < <(git diff --name-only "$LOCK_REF")
mapfile -t DIRS < <(printf '%s\n' "${FILES[@]}" | xargs -I{} dirname {} | sort -u)

for f in "${FILES[@]}"; do
  [ -f "$f" ] && chown root:root "$f" && chmod 444 "$f"
done

for d in "${DIRS[@]}"; do
  chown root:root "$d" && chmod 555 "$d"
done
```

### Unlock Script

Runs as root. Restores ownership to `gem`.

```bash
#!/bin/unlock
# unlock-tests.sh — run as root

LOCK_REF="${1:-HEAD}"

mapfile -t FILES < <(git diff --name-only "$LOCK_REF")
mapfile -t DIRS < <(printf '%s\n' "${FILES[@]}" | xargs -I{} dirname {} | sort -u)

for f in "${FILES[@]}"; do
  [ -f "$f" ] && chown gem:gem "$f" && chmod 644 "$f"
done

for d in "${DIRS[@]}"; do
  chown gem:gem "$d" && chmod 755 "$d"
done
```

### Validation Step

After implementation, confirm no test files mutated:

```bash
#!/bin/bash
# validate-tests.sh — exits non-zero if test files changed
TEST_COMMIT="${1:?usage: validate-tests.sh <test-commit-sha>}"

CHANGED=$(git diff --name-only "$TEST_COMMIT"..HEAD -- $(git diff --name-only "$TEST_COMMIT"))
if [ -n "$CHANGED" ]; then
  echo "ERROR: test files modified during implementation:"
  echo "$CHANGED"
  exit 1
fi
echo "OK: no test files modified"
```

## Security Properties

| Threat | Mitigation |
|--------|------------|
| Agent edits test file | File owned by root, `gem` can't write |
| Agent `chmod` back | `gem` can't chown root-owned files |
| Agent creates new file in test dir | Directory owned by root, mode `555` — no write |
| Agent modifies non-test code during test phase | Out of scope — test phase has full access by design |

## Edge Cases

| Case | Handling |
|------|----------|
| Test phase touches config/build files | All changes in the commit get locked. If config must remain writable, use a `.lockignore` or explicit allowlist. |
| Multiple commits during test phase | Use range: `lock-tests.sh <first-commit>..HEAD` |
| Agent needs to read tests during implementation | `chmod 444` = readable by everyone |
| Project has no tests yet | Empty diff → no-op. Lock is a no-op. |

## Integration with Trailhead

Workflow YAML with lock/unlock stages:

```yaml
name: tdd
stages:
  - name: write-tests
    prompt: "Write tests for {description}. Do not write implementation code."
  - name: review
    approval_required: true
  - name: lock-tests
    action: run_script
    script: lock-tests.sh HEAD
    user: root
  - name: implement
    prompt: "Implement code to pass the tests. Tests are read-only — do not modify them."
  - name: validate-tests
    action: run_script
    script: validate-tests.sh {test_commit_sha}
  - name: unlock-tests
    action: run_script
    script: unlock-tests.sh HEAD
    user: root
```

The scheduler already runs as root on the host. Worker containers run processes as `gem`. The lock/unlock scripts execute as host-level pre/post hooks (not inside the worker) — the worker never gets root.

## Implementation Checklist

- [ ] Add `lock-tests.sh` and `unlock-tests.sh` to worker image or host scripts
- [ ] Add `validate-tests.sh` for post-implementation verification
- [ ] Add workflow stage hooks for pre/post scripts with `user` field
- [ ] Scheduler captures test commit SHA at review stage, passes to lock/validate
- [ ] Test with `test-workspace/` fixture project
