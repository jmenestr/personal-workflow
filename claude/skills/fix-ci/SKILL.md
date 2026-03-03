---
name: fix-ci
description: Fix CI failures on your PR. Auto-fixes lint, TypeScript, and build errors in a worktree. Flags flaky tests and timeouts for manual retry. Polls pending jobs every 3 minutes until settled.
---

# /fix-ci Skill

You're in the Unblock loop. Watch CI on the PR, fix what's automatically fixable, surface what isn't, and poll until everything has settled.

## Usage

`/fix-ci [PR number]`

If no PR given, detect from current branch:
```bash
gh pr view --json number,headRefName,url 2>/dev/null
```

Assume `transcend-io/main` unless context indicates otherwise.

---

## Steps

### 1. Get the PR

```bash
PR_NUMBER=[NUMBER]
REPO="transcend-io/main"

gh pr view $PR_NUMBER --repo $REPO \
  --json number,title,headRefName,url
```

### 2. Set up a worktree

Work in an isolated worktree so the user's current checkout isn't disturbed.

```bash
BRANCH=[headRefName]
WORKTREE="/tmp/fix-ci-$PR_NUMBER"

# Create worktree if it doesn't exist
if ! git worktree list | grep -q "$WORKTREE"; then
  git fetch origin "$BRANCH"
  git worktree add "$WORKTREE" "origin/$BRANCH"
fi

cd "$WORKTREE"
```

All subsequent commands run from `$WORKTREE`.

### 3. Fetch CI check runs

```bash
gh api "repos/$REPO/commits/$(git rev-parse HEAD)/check-runs" \
  --paginate \
  --jq '.check_runs[] | {name: .name, status: .status, conclusion: .conclusion, id: .id}'
```

### 4. Categorize jobs

**Pending / queued / in_progress** → enter polling loop (step 7)

**Fixable failures** — attempt auto-fix:
| Pattern in job name | Fix approach |
|---|---|
| `lint`, `eslint` | `yarn eslint --fix` |
| `prettier`, `format` | `yarn prettier --write` |
| `typecheck`, `tsc`, `typescript`, `type-check` | Fix TS errors in code |
| `build`, `compile` | Fix broken imports/exports |

**Non-fixable failures** — report to user:
- Job name contains `test`, `spec`, `jest`, `integration`, `e2e`, `cypress`
- `conclusion: timed_out`
- `conclusion: infrastructure_fail`
- Any job that has failed 2+ times with the same error

---

### 5. For each fixable failure — fetch logs and fix

```bash
# Get job logs
gh api "repos/$REPO/actions/jobs/[JOB_ID]/logs" 2>/dev/null | tail -150
```

Read the log carefully. Identify the specific files and errors before touching anything.

**ESLint:**
```bash
# Try auto-fix first
yarn eslint --fix [specific files from log]
# Verify
yarn eslint [specific files]
```

**Prettier:**
```bash
yarn prettier --write [specific files from log]
```

**TypeScript:**
```bash
# Get full error list
yarn tsc --noEmit 2>&1

# Read each erroring file, fix the type error
# Re-run to confirm clean — do not commit with TS errors remaining
yarn tsc --noEmit 2>&1 | grep -c "error TS" || echo "✓ TS clean"
```

**Build failures:**
```bash
yarn build 2>&1 | tail -80
# Fix missing imports, broken re-exports, etc.
```

Use `yarn` not `npx`. Make targeted changes only — do not refactor surrounding code.

After all fixes, do a final local check:
```bash
yarn tsc --noEmit 2>&1 | tail -10
```

### 6. Commit and push

```bash
git add [only the files you changed]
git commit -m "$(cat <<'EOF'
fix: resolve CI failures

[brief description of what was fixed]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
git push origin "$BRANCH"
```

---

### 7. Polling loop

After pushing (or if the only failures are non-fixable), poll for results:

```bash
while true; do
  CHECKS=$(gh api "repos/$REPO/commits/$(git rev-parse HEAD)/check-runs" \
    --jq '.check_runs[] | {name: .name, status: .status, conclusion: .conclusion, id: .id}')

  PENDING=$(echo "$CHECKS" | jq -s '[.[] | select(.status == "in_progress" or .status == "queued")] | length')
  FAILED=$(echo "$CHECKS"  | jq -s '[.[] | select(.conclusion == "failure" or .conclusion == "timed_out")] | length')
  PASSED=$(echo "$CHECKS"  | jq -s '[.[] | select(.conclusion == "success")] | length')

  echo "→ CI: ${PASSED} passed  ${FAILED} failed  ${PENDING} pending"

  if [ "$PENDING" -eq 0 ]; then
    echo "→ All jobs settled."
    break
  fi

  echo "→ Jobs still running — checking again in 3 minutes..."
  sleep 180
done
```

After each settled cycle, re-run step 4 — new failures may have appeared that are fixable. Keep looping until no pending jobs remain and no new fixable failures exist.

---

### 8. Final report

```
### Fix-CI: PR #[NUMBER] — [TITLE]

**Fixed automatically**
- [job name] — [what changed, which files]
- ...

**Passing**
- [N] jobs green

**Retry manually** (run `gh pr checks [NUMBER] --repo transcend-io/main`)
- [job name] — flaky test, retry with: `gh run rerun [RUN_ID] --failed`
- [job name] — timed out, likely infrastructure — retry with: `gh run rerun [RUN_ID]`
- [job name] — [reason it can't be auto-fixed]
```

Provide the exact `gh run rerun` commands so the user can act immediately.

Clean up the worktree when done:
```bash
git worktree remove "$WORKTREE" --force 2>/dev/null
```
