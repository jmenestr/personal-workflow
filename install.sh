#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing personal workflow from $REPO_DIR..."

# ── Claude skills ──────────────────────────────────────────────────────────────
SKILLS_SRC="$REPO_DIR/claude/skills"
SKILLS_DEST="$HOME/.claude/skills"

mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_dir")"
  dest="$SKILLS_DEST/$skill_name"
  mkdir -p "$dest"
  cp "$skill_dir/SKILL.md" "$dest/SKILL.md"
  echo "  ✓ skill: $skill_name"
done

# ── CLAUDE.md ──────────────────────────────────────────────────────────────────
CLAUDE_DEST="$HOME/.claude/CLAUDE.md"
cp "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DEST"
echo "  ✓ CLAUDE.md → $CLAUDE_DEST"

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

echo ""
echo "Done. Skills, CLAUDE.md, shell functions, and cursor rules are installed."
