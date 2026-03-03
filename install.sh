#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing personal workflow from $REPO_DIR..."

# ── Skills (Claude + Cursor) ───────────────────────────────────────────────────
SKILLS_SRC="$REPO_DIR/claude/skills"

for dest_base in "$HOME/.claude/skills" "$HOME/.cursor/skills"; do
  mkdir -p "$dest_base"
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name="$(basename "$skill_dir")"
    dest="$dest_base/$skill_name"
    mkdir -p "$dest"
    cp "$skill_dir/SKILL.md" "$dest/SKILL.md"
  done
  echo "  ✓ skills → $dest_base"
done

# ── CLAUDE.md + AGENTS.md ──────────────────────────────────────────────────────
cp "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "  ✓ CLAUDE.md → ~/.claude/CLAUDE.md"

mkdir -p "$HOME/.cursor"
cp "$REPO_DIR/claude/CLAUDE.md" "$HOME/.cursor/AGENTS.md"
echo "  ✓ AGENTS.md → ~/.cursor/AGENTS.md"

# ── Shell functions ────────────────────────────────────────────────────────────
SHELL_FUNCTIONS_SRC="$REPO_DIR/claude/shell-functions.zsh"
if [[ -f "$SHELL_FUNCTIONS_SRC" ]]; then
  if grep -q "Claude Code shell functions" ~/.zshrc 2>/dev/null; then
    echo "  ✓ shell functions already in ~/.zshrc"
  else
    echo "" >> ~/.zshrc
    cat "$SHELL_FUNCTIONS_SRC" >> ~/.zshrc
    echo "  ✓ shell functions → ~/.zshrc"
  fi
fi

# ── Cursor rules ───────────────────────────────────────────────────────────────
RULES_SRC="$REPO_DIR/cursor/rules"
RULES_DEST="$HOME/.cursor/rules"

mkdir -p "$RULES_DEST"

for rule in "$RULES_SRC"/*.mdc; do
  cp "$rule" "$RULES_DEST/"
  echo "  ✓ cursor rule: $(basename "$rule")"
done

# ── Claude settings ────────────────────────────────────────────────────────────
SETTINGS_SRC="$REPO_DIR/claude/settings.json"
SETTINGS_DEST="$HOME/.claude/settings.json"

if [[ -f "$SETTINGS_SRC" ]]; then
  cp "$SETTINGS_SRC" "$SETTINGS_DEST"
  echo "  ✓ settings.json → $SETTINGS_DEST"
fi

# ── Cursor agent (Linux only) ──────────────────────────────────────────────────
if [[ "$(uname)" == "Linux" ]]; then
  if command -v cursor &>/dev/null; then
    echo "  ✓ Cursor agent already installed"
  else
    echo "  → Installing Cursor agent..."
    curl https://cursor.com/install -fsS | bash && echo "  ✓ Cursor agent installed"
  fi
fi

echo ""
echo "Done. Skills (Claude + Cursor), CLAUDE.md, AGENTS.md, shell functions, cursor rules, and settings are installed."
