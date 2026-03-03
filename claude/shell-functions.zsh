# ── Claude Code shell functions ─────────────────────────
# Installed by personal-workflow/install.sh → ~/.zshrc
# Invoke from terminal: review, fix-ci, fix-comments, etc.

# Use explicit path to avoid yarn/workspace alias hijacking
# Resolve the best available base ref (works in worktrees too)
_git_base() {
  local base=${1:-main}
  local result
  result=$(git merge-base HEAD "origin/$base" 2>/dev/null) && echo "$result" && return
  result=$(git merge-base HEAD "$base" 2>/dev/null) && echo "$result" && return
  result=$(git rev-parse "origin/$base" 2>/dev/null) && echo "$result" && return
  result=$(git rev-parse "$base" 2>/dev/null) && echo "$result" && return
  echo "HEAD~1"
}


# Review all changes vs base branch. Usage: review [base]
review() {
  local base=${1:-main}
  claude "You are a senior engineer doing a pre-PR code review.
Base branch: $base
Diff: $(git diff $(_git_base $base))
Changed files: $(git diff $(_git_base $base) --name-only)

Review for:
1. Logic errors or missed edge cases
2. Missing error handling
3. Inconsistent patterns vs the rest of the codebase
4. Anything that would get flagged in human review

Output as a markdown checklist grouped by file.
Mark items: [BLOCKER] [SUGGESTION] [NITPICK]"
}

# Generate PR description from current branch. Usage: prprep [base]
prprep() {
  local base=${1:-main}
  claude "Generate a pull request description for this branch.
Branch: $(git branch --show-current)
Commits: $(git log $(_git_base $base)..HEAD --oneline)
Diff summary: $(git diff $(_git_base $base) --stat)

Sections: ## What, ## How, ## Testing, ## Notes"
}

# Write tests for a file. Usage: writetests <file>
writetests() {
  [ -z "$1" ] && echo "Usage: writetests <file>" && return 1
  claude "Write comprehensive tests for this file.
File: $1
Contents:
$(cat $1)

Requirements:
- Match the existing test patterns in this repo
- Cover happy path, edge cases, and error cases
- Use the same test framework already in use
- Output ONLY the test file contents, no explanation."
}

# Targeted refactor with guardrails. Usage: refactor <file> "instruction"
refactor() {
  [ -z "$1" ] || [ -z "$2" ] && echo "Usage: refactor <file> \"<instruction>\"" && return 1
  claude "Refactor this file.
File: $1
Contents:
$(cat $1)

Instruction: $2

Rules:
- Do not change external interfaces or function signatures
- Match existing code style and patterns
- Output the complete refactored file, ready to save."
}

# ── CI fix workflow ──────────────────────────────────────
# Fetches failed CI logs for a PR and has Claude fix them automatically.
# Polls until CI is complete if still running.
# Usage: fix-ci <PR-URL>
fix-ci() {
  [ -z "$1" ] && echo "Usage: fix-ci <PR-URL>" && return 1
  local pr_url="$1"

  # Extract owner/repo/number from URL
  local pr_number=$(echo "$pr_url" | grep -o '[0-9]*$')
  local repo=$(echo "$pr_url" | sed 's|https://github.com/||' | cut -d'/' -f1-2)

  echo "→ Checking CI status for PR #$pr_number in $repo..."

  # Poll until all checks are complete (not queued/in_progress)
  local max_attempts=20
  local attempt=0
  while true; do
    local status=$(gh pr checks "$pr_number" --repo "$repo" 2>/dev/null)
    local pending=$(echo "$status" | grep -c "pending\|in_progress\|queued" || true)

    if [ "$pending" -eq 0 ]; then
      echo "✓ CI complete"
      break
    fi

    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "✗ Timed out waiting for CI (${max_attempts} attempts). Current status:"
      echo "$status"
      return 1
    fi

    echo "  CI still running ($pending checks pending) — polling in 30s... ($attempt/$max_attempts)"
    sleep 30
  done

  # Get failed checks
  local failed=$(gh pr checks "$pr_number" --repo "$repo" 2>/dev/null | grep "fail\|error" || true)
  if [ -z "$failed" ]; then
    echo "✓ All CI checks passed — nothing to fix"
    return 0
  fi

  echo "✗ Failed checks:"
  echo "$failed"
  echo ""

  # Fetch logs for each failed run
  local run_ids=$(gh run list --repo "$repo" --branch "$(git branch --show-current)" \
    --json databaseId,status,conclusion \
    --jq '.[] | select(.conclusion == "failure") | .databaseId' 2>/dev/null | head -5)

  local all_logs=""
  for run_id in $run_ids; do
    echo "→ Fetching logs for run $run_id..."
    local logs=$(gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null | tail -200)
    all_logs="$all_logs\n\n=== Run $run_id ===\n$logs"
  done

  if [ -z "$all_logs" ]; then
    echo "✗ Could not fetch run logs. Try: gh run list --repo $repo"
    return 1
  fi

  echo "→ Passing failures to Claude Code to fix..."
  claude "You are a senior engineer fixing CI failures.

PR: $pr_url
Branch: $(git branch --show-current)
Current diff vs main: $(git diff $(_git_base) --stat)

Failed CI logs:
$all_logs

Instructions:
1. Analyze the failures and identify root causes
2. Fix the issues directly in the codebase
3. Do not change unrelated code
4. After fixing, explain what you changed and why"
}

# ── PR comments workflow ─────────────────────────────────
# Fetches open review comments on a PR.
# Fixes obvious ones automatically, asks about ambiguous ones.
# Marks unfixable ones as resolved with an explanation comment.
# Usage: fix-comments <PR-URL>
fix-comments() {
  [ -z "$1" ] && echo "Usage: fix-comments <PR-URL>" && return 1
  local pr_url="$1"

  local pr_number=$(echo "$pr_url" | grep -o '[0-9]*$')
  local repo=$(echo "$pr_url" | sed 's|https://github.com/||' | cut -d'/' -f1-2)

  echo "→ Fetching review comments for PR #$pr_number..."

  # Get all unresolved review comments
  local comments=$(gh api "repos/$repo/pulls/$pr_number/comments" \
    --jq '.[] | "FILE: \(.path)\nLINE: \(.line // .original_line)\nAUTHOR: \(.user.login)\nCOMMENT: \(.body)\nID: \(.id)\n---"' \
    2>/dev/null)

  if [ -z "$comments" ]; then
    echo "✓ No open review comments found"
    return 0
  fi

  local comment_count=$(echo "$comments" | grep -c "^FILE:" || true)
  echo "Found $comment_count comment(s)"
  echo ""

  git fetch origin --quiet 2>/dev/null || true
  local base=$(_git_base)
  local current_diff=$(git diff "$base" 2>/dev/null || git diff HEAD~1 2>/dev/null || echo "(diff unavailable)")

  claude "You are a senior engineer addressing PR review comments.

PR: $pr_url
Repo: $repo
Branch: $(git branch --show-current)
Current diff vs main:
$current_diff

Open review comments:
$comments

Instructions:
1. For each comment, decide if it is:
   - OBVIOUS: clear, unambiguous fix (just do it)
   - AMBIGUOUS: requires design judgment or clarification (ask me before changing anything)
   - UNFIXABLE: not applicable, already handled, or incorrect feedback

2. For OBVIOUS comments: fix the code directly, no questions asked.

3. For AMBIGUOUS comments: stop and ask me specifically:
   - What the comment is asking
   - What options you see
   - Which you'd recommend and why
   Wait for my response before making any changes.

4. For UNFIXABLE comments: do NOT change code. Instead output a list of
   comment IDs with a one-sentence explanation for each so I can post
   a reply and resolve them manually.

5. After all fixes, summarize what you changed and what needs manual resolution."
}

# ── git-standup ──────────────────────────────────────────
# Summarizes your commits in the last 24hrs as a standup update.
# Usage: git-standup
git-standup() {
  local since=${1:-"24 hours ago"}
  local log=$(git log --all --author="$(git config user.email)" \
    --since="$since" --oneline --no-merges 2>/dev/null)

  if [ -z "$log" ]; then
    echo "No commits in the last 24 hours."
    return 0
  fi

  claude "Generate a brief engineering standup update from these commits.

Author: $(git config user.name)
Period: last 24 hours
Commits:
$log

Format:
## Yesterday
[what was done, grouped by theme, plain english not commit messages]

## Today
[infer what likely comes next based on the commits]

## Blockers
[only if obvious from commit messages, otherwise omit]

Keep it concise — 3-5 bullet points max per section."
}

# ── checkpoint ───────────────────────────────────────────
# WIP commit + push. For switching contexts without losing work.
# Usage: checkpoint "optional message"
checkpoint() {
  local msg=${1:-"WIP checkpoint $(date '+%Y-%m-%d %H:%M')"}
  git add -A
  git commit -m "chore: $msg" --no-verify
  git push origin "$(git branch --show-current)" --no-verify
  echo "✓ Checkpoint saved: $msg"
}

# ── explain ──────────────────────────────────────────────
# Explains what a file does, its dependencies, and where it fits.
# Usage: explain <file>
explain() {
  [ -z "$1" ] && echo "Usage: explain <file>" && return 1
  claude "Explain this file to a senior engineer joining the codebase.

File: $1
Contents:
$(cat $1)

Cover:
1. What this file does in one sentence
2. Key functions/classes and what they do
3. What calls this / what this calls (based on imports and exports)
4. Any non-obvious patterns or decisions worth knowing
5. What you'd need to understand to safely modify this file

Be concise — this is a reference, not a tutorial."
}

# ── findbugs ─────────────────────────────────────────────
# Looks specifically for bugs in changed files, not style issues.
# Usage: findbugs [base]
findbugs() {
  local base=${1:-origin/main}
  local diff=$(git diff $(_git_base $base))
  [ -z "$diff" ] && echo "No changes vs $base" && return 0

  claude "You are a senior engineer doing a bug-focused code review.
Look ONLY for bugs — not style, not nitpicks, not improvements.

Base: $base
Changed files: $(git diff $(_git_base $base) --name-only)
Diff:
$diff

Flag only:
1. Logic errors that would cause incorrect behavior
2. Race conditions or concurrency issues
3. Null/undefined access that would throw at runtime
4. Off-by-one errors
5. Missing error handling that would cause silent failures
6. Security issues (injection, auth bypass, data exposure)

For each bug: file, line, what's wrong, and a concrete fix.
If no bugs found, say so clearly."
}

# ── impact ───────────────────────────────────────────────
# Traces what depends on a file and what could break if you change it.
# Usage: impact <file>
impact() {
  [ -z "$1" ] && echo "Usage: impact <file>" && return 1
  local file=$1

  # Find files that import this file
  local importers=$(grep -rl "$(basename $file .ts)" --include="*.ts" \
    $(git rev-parse --show-toplevel) 2>/dev/null | grep -v "node_modules" | grep -v "$file" | head -20)

  claude "Analyze the blast radius of changing this file.

File: $file
Contents:
$(cat $file)

Files that import this:
$importers

Based on the exports of this file and what imports it:
1. What are the public interfaces (exported functions, types, classes)?
2. Which importers are most likely to break if the interfaces change?
3. What changes would be safe (internal only) vs risky (touches exports)?
4. What should I test after modifying this file?

Be specific about which functions/types are highest risk."
}

# ── draft-pr ─────────────────────────────────────────────
# Creates a GitHub draft PR with a Claude-generated description.
# Usage: draft-pr [base]
draft-pr() {
  local base=${1:-main}
  local branch=$(git branch --show-current)

  [ "$branch" = "main" ] && echo "✗ Can't create PR from main branch" && return 1

  echo "→ Generating PR description..."
  local description=$(claude "Generate a pull request description.
Branch: $branch
Commits: $(git log $(_git_base $base)..HEAD --oneline 2>/dev/null || git log $(_git_base $base)..HEAD --oneline)
Diff summary: $(git diff $(_git_base $base) --stat 2>/dev/null || git diff $(_git_base $base) --stat)

Sections: ## What, ## How, ## Testing, ## Notes
Be concise and specific. No filler." 2>/dev/null | grep -v "^>" | tail -n +2)

  echo "→ Creating draft PR..."
  gh pr create \
    --draft \
    --base "$base" \
    --title "$(git log -1 --pretty=%s)" \
    --body "$description" \
    --web
}

# ── respond-to-review ────────────────────────────────────
# Drafts reply comments for each PR review comment for you to review.
# Usage: respond-to-review <PR-URL>
respond-to-review() {
  [ -z "$1" ] && echo "Usage: respond-to-review <PR-URL>" && return 1
  local pr_url="$1"
  local pr_number=$(echo "$pr_url" | grep -o '[0-9]*$')
  local repo=$(echo "$pr_url" | sed 's|https://github.com/||' | cut -d'/' -f1-2)

  local comments=$(gh api "repos/$repo/pulls/$pr_number/comments" \
    --jq '.[] | "AUTHOR: \(.user.login)\nFILE: \(.path)\nCOMMENT: \(.body)\nID: \(.id)\n---"' 2>/dev/null)

  [ -z "$comments" ] && echo "✓ No open review comments" && return 0

  claude "Draft professional reply comments for each PR review comment.

PR: $pr_url
Branch: $(git branch --show-current)
My changes: $(git diff $(_git_base) --stat 2>/dev/null)

Review comments:
$comments

For each comment write a reply that:
- Acknowledges the feedback
- Explains what was done (if fixed) or why it was left as-is
- Is professional and concise (1-3 sentences max)

Format output as:
COMMENT ID: [id]
REPLY: [your reply text]
---"
}

# ── implement ────────────────────────────────────────────
# Plan-first implementation. Claude writes a plan, waits for approval, then implements.
# Usage: implement "description of what to build"
implement() {
  [ -z "$1" ] && echo "Usage: implement \"description\"" && return 1

  echo "→ Generating implementation plan..."
  echo ""

  claude "You are a senior engineer about to implement a feature.

Request: $1
Current branch: $(git branch --show-current)
Recent context: $(git log origin/main..HEAD --oneline 2>/dev/null | head -5)
Relevant files: $(git diff $(_git_base) --name-only 2>/dev/null)

STEP 1 — Write an implementation plan only. Do NOT write any code yet.

Plan format:
## Approach
[1-2 sentence summary of the approach]

## Files to change
[list each file and what change is needed]

## Files to create
[list any new files needed]

## Edge cases to handle
[list non-obvious things to consider]

## What I will NOT do
[scope boundaries — what's out of scope]

After writing the plan, end with exactly this line:
READY TO IMPLEMENT — press enter to proceed or type changes to the plan"

  echo ""
  echo -n "→ Approve plan? (enter to proceed, or describe changes): "
  read approval

  if [ -n "$approval" ]; then
    claude "Revised plan request: $approval

Original request: $1

Update your plan accordingly, then implement it."
  else
    claude "The plan was approved. Now implement it.

Original request: $1
Branch: $(git branch --show-current)

Implement exactly what was in the plan. Make the actual code changes."
  fi
}

# ── migrate ──────────────────────────────────────────────
# Applies a consistent change across all files matching a pattern.
# Usage: migrate "*.service.ts" "convert callbacks to async/await"
migrate() {
  [ -z "$1" ] || [ -z "$2" ] && echo "Usage: migrate \"<glob>\" \"<instruction>\"" && return 1
  local pattern="$1"
  local instruction="$2"
  local root=$(git rev-parse --show-toplevel)

  local files=$(find "$root" -name "$pattern" -not -path "*/node_modules/*" 2>/dev/null)
  local count=$(echo "$files" | grep -c "." || true)

  [ -z "$files" ] && echo "✗ No files matching: $pattern" && return 1

  echo "→ Found $count file(s) matching '$pattern'"
  echo "$files"
  echo ""
  echo -n "→ Apply '$instruction' to all $count files? (enter to proceed, Ctrl+C to cancel): "
  read confirm

  claude "Apply a consistent migration across multiple files.

Instruction: $instruction
Files to migrate:
$files

File contents:
$(for f in $files; do echo "=== $f ==="; cat "$f"; echo ""; done)

Rules:
- Apply the instruction consistently across ALL files
- Match each file's existing style
- Do not change anything unrelated to the instruction
- Output each modified file in full with a header: === filename ==="
}
# ── deploy-fix ───────────────────────────────────────────
# Fetches failed deployment logs and has Claude diagnose + fix interactively.
# Usage: deploy-fix <GitHub-Actions-run-URL>
deploy-fix() {
  [ -z "$1" ] && echo "Usage: deploy-fix <GitHub-Actions-run-URL>" && return 1
  local run_url="$1"

  # Extract run ID and repo from URL
  # e.g. https://github.com/transcend-io/main/actions/runs/12345
  local run_id=$(echo "$run_url" | grep -o '[0-9]*$')
  local repo=$(echo "$run_url" | sed 's|https://github.com/||' | cut -d'/' -f1-2)

  echo "→ Fetching failed jobs for run $run_id in $repo..."

  # Get failed jobs immediately — don't wait for run to complete
  local failed_jobs=$(gh run view "$run_id" --repo "$repo" --json jobs     --jq '.jobs[] | select(.conclusion == "failure") | .databaseId' 2>/dev/null)

  if [ -z "$failed_jobs" ]; then
    echo "✗ No failed jobs found yet — run may still be in progress"
    echo "  Tip: re-run deploy-fix once jobs start failing"
    return 1
  fi

  echo "→ Fetching logs from failed jobs..."
  local logs=""
  for job_id in $failed_jobs; do
    logs="$logs
$(gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null | tail -300)"
  done

  if [ -z "$logs" ]; then
    echo "✗ Could not fetch logs"
    return 1
  fi

  claude "You are a senior DevOps engineer helping fix a failed deployment.

Run URL: $run_url
Repo: $repo

Failed logs (last 300 lines):
$logs

Common failure patterns and fixes:
- BucketNotEmpty: empty all object versions then retry
  aws s3api delete-objects --bucket BUCKET --delete \"\$(aws s3api list-object-versions --bucket BUCKET --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)\"
  aws s3api delete-objects --bucket BUCKET --delete \"\$(aws s3api list-object-versions --bucket BUCKET --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)\"
- Pulumi resource already exists: pulumi import <type> <name> <id>
- Bucket ACL blocked: aws s3api delete-bucket-ownership-controls --bucket BUCKET
- S3 public access blocked: aws s3api delete-public-access-block --bucket BUCKET

Instructions:
1. Diagnose what failed and why
2. Run the fix commands directly — you have access to AWS CLI and Pulumi
3. Confirm when fixed and tell me to re-trigger the deployment at: $run_url"
}
