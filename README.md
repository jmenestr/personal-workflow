# personal-workflow

My personal Claude Code skills, cursor rules, and session context — decoupled from any company repo.

Bootstrapped into GitHub Codespaces via [my dotfiles gist](https://gist.github.com/jmenestr/82dc058f61e8e592e877987c29986c3d).

---

## What's in here

```
claude/
  CLAUDE.md           Personal context loaded into every Claude Code session
  skills/
    review/           Deep PR review with project context
    scope/            Turn vague requirements into concrete specs
    think/            Structured thinking partner for ambiguous problems
    thread/           Read + synthesize Slack threads, draft response
    standup/          Generate standup from Linear + GitHub activity
    rfc/              Turn fuzzy discussions into structured proposals

cursor/
  rules/
    typescript-domain-patterns.mdc    Value objects, no primitive obsession
    error-handling.mdc                No silent failures, proper propagation
    ai-verification.mdc               Flag things that need human review
    observability.mdc                 Datadog metrics + structured logging
    builder-patterns.mdc              DynamoDB key builders, repository pattern
```

---

## Install

```bash
git clone https://github.com/jmenestr/personal-workflow.git ~/personal-workflow
cd ~/personal-workflow
chmod +x install.sh
./install.sh
```

This copies:
- `claude/skills/*` → `~/.claude/skills/`
- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `cursor/rules/*.mdc` → `~/.cursor/rules/`

---

## Skills

These skills are designed for use inside a Codespace, where you have:
- A GitHub repo checked out
- Linear MCP configured
- Slack MCP configured (optional)

| Skill | When to use |
|-------|------------|
| `/review` | Before approving a PR — flags arch concerns beyond line-by-line |
| `/scope` | When a Linear issue or Slack request is too vague to start on |
| `/think` | When you're tagged in something ambiguous and need to form a view |
| `/thread` | When a Slack thread needs a thoughtful reply, not a quick ack |
| `/standup` | Generate standup from actual Linear + GitHub activity |
| `/rfc` | Turn a circular discussion into a proposal with options + tradeoff |

---

## Cursor rules

Rules apply automatically when Cursor is open in a TypeScript project. The domain-specific rules (`builder-patterns`) are scoped to consent/preference management paths and won't activate elsewhere.

---

## Updating

To add or edit a skill, edit in `~/personal-workflow/claude/skills/[name]/SKILL.md`, then run `./install.sh` to sync to `~/.claude/skills/`.

Pull latest from GitHub to get updates across machines:
```bash
cd ~/personal-workflow && git pull && ./install.sh
```
