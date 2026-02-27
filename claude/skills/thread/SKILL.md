---
name: thread
description: Read a Slack thread you're tagged in, synthesize what's actually being asked, map positions in play, and draft your response. For ambiguous discussions that need thought before you reply.
---

# /thread Skill

Process a Slack thread that needs a thoughtful response. Synthesize the discussion, figure out what's actually being asked, and help formulate a clear position — then draft a reply in the user's voice.

## Usage

The user invokes this as: `/thread [slack URL or description of the thread]`

Extract either:
- A Slack URL (e.g. `https://transcend-io.slack.com/archives/C.../p...`) — read the thread directly
- A description of the thread/channel — search for it

If neither is provided, ask for the thread URL or channel + topic before proceeding.

## Steps

### 1. Read the Slack thread

If a URL is provided, use the Slack MCP tool to read the thread:
- Extract channel ID and thread timestamp from the URL
- Use `slack_read_thread` to get the full thread

If only a description is provided:
- Use `slack_search_public_and_private` to find the thread
- Read the most relevant result

### 2. Search for related context in Slack

Based on the topic of the thread, search for related prior discussions:
- Use `slack_search_public_and_private` with 2–3 key terms from the thread
- Look for decisions that were already made, prior debates, or established context

### 3. Read relevant vault notes

Search the vault for the thread's topic:
```bash
VAULT="/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/The Workshop"
grep -ril "[KEY_TERMS]" "$VAULT" --include="*.md" 2>/dev/null
```

Read any matching files — especially `Life/` notes for standing beliefs and `Projects/` for relevant technical context.

### 4. Check Linear for related issues

If the thread references a feature, bug, or technical area, use the Linear MCP tools to find any related issues assigned to or involving the user.

---

## Synthesis

Produce:

### Thread: [CHANNEL / TOPIC]

**What's actually being asked** — strip away the noise and state the real question or decision in one sentence. Often threads meander; find the crux.

**Positions in play** — who is saying what? Map the key perspectives, including any implied but unstated positions. Quote directly where it matters.

**What you need to decide or respond to** — is this:
- A question only you can answer?
- A decision being escalated to you?
- A request for your opinion?
- Something you've been tagged to acknowledge or action?

Name it exactly.

**Your position** — based on vault context, project knowledge, and the discussion itself, what do you actually think? Draft a clear stance with reasoning.

**Draft response** — write the Slack reply in the user's voice. Be direct. Match the tone of the thread (quick take vs. detailed explanation). Include any caveats or conditions that are genuinely necessary, but don't hedge where a clear answer is possible.

**Open questions** — if there's something you'd need to know before responding confidently, list it. Sometimes the right move is to ask a clarifying question rather than take a premature position.
