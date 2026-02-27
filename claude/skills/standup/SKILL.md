---
name: standup
description: Generate a standup update from your Linear and GitHub activity in the last 24 hours. Work-focused — what you actually shipped, reviewed, or moved forward.
---

# /standup Skill

Generate a concise standup update grounded in what actually happened, not what was planned. Pull Linear issue activity and GitHub PR activity from the last 24 hours and produce something you can post directly.

## Steps

Execute all reads **in parallel**, then synthesize.

### 1. Get Linear activity

Use the Linear MCP tools to:
- List issues assigned to "me" with status "Done" — check for any completed recently
- List issues assigned to "me" with status "In Progress" — note which ones had recent updates
- List issues assigned to "me" that are blocked or have comments needing response

### 2. Get GitHub PR activity

```bash
# Your PRs merged recently
gh pr list --repo transcend-io/main --author "@me" --state merged \
  --json number,title,mergedAt --limit 5 2>/dev/null

# Your open PRs — check review status
gh pr list --repo transcend-io/main --author "@me" --state open \
  --json number,title,reviewDecision,updatedAt --limit 10 2>/dev/null

# PRs you reviewed recently (review-requested, now with activity)
gh pr list --repo transcend-io/main --search "review-requested:@me is:open" \
  --json number,title,author,updatedAt --limit 10 2>/dev/null

# Also check cli repo
gh pr list --repo transcend-io/cli --author "@me" --state open \
  --json number,title,reviewDecision --limit 5 2>/dev/null
```

### 3. Read today's and yesterday's daily notes

```bash
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d)
```

Read:
```
/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop/Daily/$TODAY.md
/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop/Daily/$YESTERDAY.md
```

Look for Captures and Intentions — what was flagged as the focus?

---

## Synthesis

Produce a standup in the format used at Transcend (three parts: yesterday, today, blockers). Keep it concise — this is a standup, not a status report.

### Standup — [DATE]

**Yesterday**
- [Specific thing completed or meaningfully progressed — tie to PR numbers or issue IDs]
- [Keep to 2–4 bullets max. Skip anything trivial.]

**Today**
- [What you're focusing on — specific enough that someone could follow up]
- [Prioritized by urgency/SLA if applicable]

**Blockers**
- [Only real blockers — PRs waiting on review you've already chased, decisions you can't make alone, etc.]
- None (if clean)

---

After producing the standup, ask: "Want me to post this to Slack?" If yes, use the Slack MCP tools to send it to the appropriate standup channel.
