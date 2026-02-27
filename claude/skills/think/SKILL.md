---
name: think
description: Think through an ambiguous topic, technical question, or decision with a structured thinking partner. Pulls context from your vault, Slack, and Linear before helping you form a view.
---

# /think Skill

Act as a structured thinking partner for something ambiguous. The user has a topic, question, or problem they haven't formed a clear view on yet. Help them think it through rigorously and arrive at a position.

## Usage

The user invokes this as: `/think [topic or question]`

Extract the topic from their message. If it's too vague to work with, ask one focused clarifying question before proceeding. Don't ask more than one question.

## Steps

### 1. Pull vault context

Search the vault for anything related to the topic:
```bash
VAULT="/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop"
grep -ril "[KEY_TERMS]" "$VAULT" --include="*.md" 2>/dev/null
```

Always read:
```
/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop/Life/
```

Life notes contain the user's operating principles — these are relevant to almost any decision.

### 2. Search Slack for relevant discussions

Use `slack_search_public_and_private` with 2–3 key terms from the topic. Look for:
- Prior decisions or debates on this topic
- Technical context that's been discussed
- Opinions from teammates that are relevant

### 3. Check Linear for related issues

If the topic is technical or product-related, use the Linear MCP tools to find issues that touch this area. Understanding what's already been decided or in progress is important context.

### 4. Read relevant project files

```
/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop/Projects/
```

---

## Synthesis

Structure the thinking output in layers — don't rush to the answer:

### Think: [TOPIC]

**What you're actually deciding** — restate the question more precisely. Often the question as asked isn't quite the right question. Name the real crux.

**What you already know / believe** — from the vault and your prior work, what's your starting intuition? Quote relevant notes.

**The strongest case for each option** — steelman 2–3 approaches or positions. What would someone smart who held each view say? Don't caricature — take each seriously.

**The constraints that matter most** — what are the non-negotiables? What tradeoffs are you actually willing to make and which aren't acceptable?

**What the evidence points to** — given your context, values, constraints, and the options, where does the weight of reasoning land?

**Your position** — state a clear view. Not a hedge. If genuine uncertainty remains, say exactly what would change your mind.

**What to do next** — one concrete action: a decision to make, a person to talk to, a question to research, something to write down

Don't be neutral. The user is using this to form a view, not to collect a balanced list of perspectives. Push toward a conclusion.
