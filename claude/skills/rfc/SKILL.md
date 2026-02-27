---
name: rfc
description: Turn a fuzzy idea or circular Slack discussion into a structured proposal — problem, options, tradeoffs, and a recommendation. Produces a document you can share.
---

# /rfc Skill

Write a mini RFC (Request for Comment) for a technical decision, product direction, or architectural choice. Useful when a Slack thread has been going in circles and someone needs to write something down.

## Usage

The user invokes this as: `/rfc [topic, Slack URL, or Linear issue]`

Parse the input:
- Slack URL → read the thread to understand the discussion
- Linear ID → fetch the issue
- Description → use directly

If no input is given, ask what the RFC should be about.

## Steps

### 1. Get the source material

**If Slack URL:**
Use the Slack MCP tools to read the thread. Extract:
- The core question or decision being debated
- Positions already staked out
- Constraints or requirements mentioned
- Who the key stakeholders are

**If Linear ID:**
Use the Linear MCP tools to fetch the full issue and any comments.

### 2. Search for prior decisions and context

Use `slack_search_public_and_private` with key terms to find:
- Prior RFCs or proposals on related topics
- Design discussions that established relevant constraints
- Any decisions that are already settled and should be treated as fixed

### 3. Read vault context

```bash
VAULT="/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop"
grep -ril "[KEY_TERMS]" "$VAULT" --include="*.md" 2>/dev/null
```

Read `Projects/` for architecture context. Read `Life/software-engineering.md` for the user's engineering principles — these should inform the recommendation.

### 4. Check for related Linear issues

Use Linear MCP tools to understand the broader project context. The RFC should be anchored to real work, not float free.

---

## Synthesis

Produce the RFC in a format that can be directly shared in Slack or a document:

---

# RFC: [TITLE]

**Author:** Justin Menestrina
**Date:** [TODAY]
**Status:** Draft

## Problem

[2–3 sentences: what is broken, unclear, or suboptimal? Why does a decision need to be made?]

## Background

[What context is needed to understand the decision? Prior decisions, relevant constraints, how we got here. Keep it factual.]

## Options

### Option A: [Name]
[Description]
**Pros:** ...
**Cons:** ...

### Option B: [Name]
[Description]
**Pros:** ...
**Cons:** ...

### Option C: [Name, if applicable]
...

## Recommendation

**[Option X]**, because [direct reasoning grounded in the constraints and tradeoffs above].

[1–2 sentences explaining why the other options were ruled out.]

## Open Questions

- [ ] [Question that must be resolved before or during implementation]
- [ ] ...

## Out of Scope

[What this RFC explicitly does not address, to prevent the discussion from expanding]

---

After generating the draft, ask the user:
- "Want me to post this to the Slack thread?"
- "Should I create a Linear issue or document for this?"
- "Anything you'd change before sharing?"
