---
name: review
description: Do a deep PR review using your project context from vault and Linear. Goes beyond line-by-line — flags architectural concerns, consistency issues, and questions a generic reviewer would miss.
---

# /review Skill

Review a pull request with the benefit of project context from the vault and linked Linear issues. Produce a structured review that's more useful than a generic diff read.

## Usage

The user invokes this as: `/review [PR number or URL]`

Extract the PR number from their message. If no PR is given, ask for one.

Assume `transcend-io/main` unless the URL or context indicates otherwise (e.g. `transcend-io/cli`).

## Steps

### 1. Fetch the PR

```bash
PR_NUMBER=[NUMBER]
REPO="transcend-io/main"  # adjust if needed

# Get PR metadata
gh pr view $PR_NUMBER --repo $REPO \
  --json number,title,body,author,additions,deletions,files,reviewDecision,labels,url

# Get the diff
gh pr diff $PR_NUMBER --repo $REPO 2>/dev/null | head -2000
```

### 2. Extract linked Linear issue

Parse the PR body and title for a Linear issue ID (e.g. `PIK-572`). If found, use the Linear MCP tools to fetch the full issue:
- Read the requirements and acceptance criteria
- Note the project and milestone
- Check for any discussion or clarifications in comments

### 3. Pull vault context for the affected area

Identify the key files changed in the PR. Search the vault for relevant architectural notes:
```bash
VAULT="/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop"
grep -ril "[KEY_TERMS_FROM_PR]" "$VAULT" --include="*.md" 2>/dev/null
```

Read `Projects/` for context on the relevant system. Read `Life/software-engineering.md` for the user's engineering principles — use these as the lens for the review.

### 4. Search Slack for related discussions

Use `slack_search_public_and_private` with the PR title and key terms to find:
- Prior decisions about the approach being taken
- Known constraints or gotchas in this area
- Any discussions about the specific Linear issue

### 5. Check for related PRs

```bash
gh pr list --repo $REPO --search "[KEY_TERMS]" --state all \
  --json number,title,state --limit 5 2>/dev/null
```

Is this PR part of a series? Understanding what came before and what comes after matters.

---

## Synthesis

Produce a structured code review. Be specific — always cite file names and line ranges. Don't pad.

### Review: PR #[NUMBER] — [TITLE]

**Summary** — one paragraph: what this PR does, whether it accomplishes it cleanly, and your overall assessment (approve / approve with comments / request changes)

**Does it match the spec?** — Cross-reference against the linked Linear issue. Does the implementation address the requirements? Are there gaps?

**Architecture & design** — does the approach fit the existing patterns? Does it introduce new abstractions that may not be warranted? Does it create technical debt?

**Concerns** (if any)
> [File:line-range] — [specific concern with reasoning]
> [File:line-range] — ...

**Questions for the author**
> - [Specific question about intent or approach]
> - ...

**Nits** (optional — only if worth mentioning)
> [File:line] — [minor style or clarity note]

**Verdict**
- ✅ Approve — [one sentence]
- ✅ Approve with comments — [what you'd like addressed]
- 🔄 Request changes — [what must change and why]

---

After generating the review, ask: "Want me to post this as a GitHub review comment?"
