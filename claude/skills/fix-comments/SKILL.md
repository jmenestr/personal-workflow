---
name: fix-comments
description: Address open review comments on your PR. Categorizes by severity, makes code changes for clear fixes, drafts responses for discussion-worthy ones. Part of the Unblock loop.
---

# /fix-comments Skill

You're in the Unblock loop. This skill handles the review comments on your PR. For each open comment: fix it in code if it's clear, draft a response if it needs discussion, skip if it's already resolved.

## Usage

The user invokes this as: `/fix-comments [PR number]`

If no PR number is given, detect from the current branch:
```bash
gh pr view --json number,title,url 2>/dev/null
```

Assume `transcend-io/main` unless context indicates otherwise.

## Steps

### 1. Fetch the PR and its review comments

```bash
PR_NUMBER=[NUMBER]
REPO="transcend-io/main"

# PR overview
gh pr view $PR_NUMBER --repo $REPO \
  --json number,title,body,headRefName,reviewDecision,reviews,url

# All review comments (inline, on the diff)
gh api repos/$REPO/pulls/$PR_NUMBER/comments \
  --jq '.[] | {id: .id, path: .path, line: .line, body: .body, user: .user.login}'

# Top-level review thread comments
gh api repos/$REPO/pulls/$PR_NUMBER/reviews \
  --jq '.[] | select(.state != "APPROVED") | {id: .id, state: .state, body: .body, user: .user.login}'
```

### 2. Fetch the diff for context

```bash
gh pr diff $PR_NUMBER --repo $REPO 2>/dev/null | head -3000
```

### 3. Pull the linked Linear issue (if any)

Parse the PR body for a Linear issue ID (e.g. `PIK-572`). If found, fetch it with the Linear MCP tools to understand the original intent — this helps you tell whether a reviewer's concern is valid or out of scope.

### 4. Categorize comments

Apply Justin's review label conventions. A comment may explicitly include the label or you should infer it:

| Label | Meaning | Action |
|-------|---------|--------|
| `[BLOCKER]` | Must fix before merge | Fix in code, or respond with a clear counter-argument if you disagree |
| `[SUGGESTION]` | Worth considering, not required | Fix if straightforward, respond if it's a tradeoff worth discussing |
| `[NITPICK]` | Style/clarity only | Fix silently unless it conflicts with codebase conventions |

If a comment has no label, infer severity from the language used.

### 5. For each comment, decide: fix or respond

**Fix in code** if:
- The change is unambiguous (rename, extract, remove dead code, add missing null check)
- It's a nitpick or style issue
- You agree with the concern

**Draft a response** if:
- The reviewer's concern is based on missing context you can clarify
- You disagree and have a technical reason
- The change would require a larger refactor that's out of scope for this PR
- The comment is asking a question rather than requesting a change

**Skip** if:
- The thread is already marked resolved on GitHub
- You already addressed it in a prior commit

### 6. Apply fixes

Read the relevant files before editing. Make targeted changes only — don't refactor surrounding code.

Respect codebase conventions:
- No `as Type` casting on uncertain types — narrow properly
- No empty catch blocks, no silent error swallowing
- No manual string parsing for compound keys (e.g. `userId = encryptedId + ' ' + partition`)
- Prefer value objects and repository pattern in domain/business logic

### 7. Produce a summary

After fixing and drafting responses, output:

---

### Fix-comments: PR #[NUMBER] — [TITLE]

**[N] comments addressed**

**Fixed in code**
- `[file:line]` — [reviewer] — [one-line description of what changed]
- ...

**Responses drafted** (post these as replies to the threads)
- `[file:line]` — [reviewer] — [your drafted response]
- ...

**Skipped** (already resolved or out of scope)
- `[file:line]` — [reason]

---

Then ask: "Want me to post the responses to GitHub?"

If yes, use `gh api` to post each drafted response as a reply to the correct review thread:
```bash
gh api repos/[REPO]/pulls/[PR]/comments/[COMMENT_ID]/replies \
  -X POST -f body="[RESPONSE]"
```
