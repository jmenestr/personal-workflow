---
name: scope
description: Take a vague requirement, Linear issue, or Slack request and break it into something concrete — actual work, open questions, decisions needed before building. Produces output you can post back to the thread or link in the issue.
---

# /scope Skill

Transform ambiguous work into a clear, actionable spec. Given a Linear issue ID, Slack thread, or description of a request, produce a scoping doc that defines what the work actually is.

## Usage

The user invokes this as: `/scope [Linear issue ID, Slack URL, or description]`

Parse the input:
- If it looks like a Linear ID (e.g. `PIK-572`), fetch the issue
- If it's a Slack URL, read the thread
- If it's a description, use it directly

If no input is given, ask for the issue or request to scope.

## Steps

### 1. Get the source material

**If Linear issue ID:**
Use the Linear MCP tools to fetch the full issue:
- `get_issue` with the issue identifier
- Note: title, description, labels, project, milestone, linked issues

**If Slack URL or topic:**
Use the Slack MCP tools to read the thread and extract the request.

### 2. Read related project context from vault

```bash
VAULT="/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop"
grep -ril "[KEY_TERMS_FROM_ISSUE]" "$VAULT" --include="*.md" 2>/dev/null
```

Read `Projects/` for architecture context. Read `Life/software-engineering.md` for engineering principles.

### 3. Search Slack for related prior work

Use `slack_search_public_and_private` to find:
- Prior discussions about this feature or area
- Design decisions that have already been made
- Any context the requester may have omitted

### 4. Check related Linear issues

Use the Linear MCP tools to find issues in the same project or with similar labels. Understanding what's adjacent prevents duplication and surfaces dependencies.

---

## Synthesis

Produce a scoping document. Keep it tight — this should be something you can post directly to the Slack thread or drop in the Linear issue description.

---

**Scope: [ISSUE TITLE or TOPIC]**

**What this is** — one sentence stating the actual request, stripped of ambiguity

**What done looks like** — 3–5 concrete acceptance criteria. Not "improve X" but "given Y input, Z happens"

**What's in scope** — explicit list of what this work includes

**What's out of scope** — equally explicit list of what it doesn't include (prevents scope creep, clears up unstated assumptions)

**Open questions** — things that must be answered before or during implementation. For each: who owns the answer?
| Question | Owner | Blocking? |
|----------|-------|-----------|

**Dependencies** — other issues, systems, or teams this work depends on or affects

**Rough size** — S / M / L / XL with one sentence of reasoning. Not a story point — just a gut check on whether this is a day, a week, or a sprint.

**Suggested first step** — what's the smallest thing that moves this forward?

---

After writing the scope, ask the user: "Want me to post this back to the Slack thread or update the Linear issue description?"
