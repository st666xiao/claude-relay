#!/usr/bin/env bash
# Copy claude-relay skills and agents into ~/.claude.
#   ./install.sh      ask before overwriting each existing file
#   ./install.sh -y   overwrite without asking (for AI agents / upgrades);
#                     existing copies are backed up to ~/.claude/backups/claude-relay-<time>/ first
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
yes=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && yes=1
backup="$dest/backups/claude-relay-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$dest/skills" "$dest/agents"

confirm() {
  if (( yes )); then
    mkdir -p "$backup/$2"
    cp -R "$1" "$backup/$2/"
    return 0
  fi
  read -r -p "$1 already exists. Overwrite? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

for dir in "$src"/skills/*/; do
  name="$(basename "$dir")"
  target="$dest/skills/$name"
  if [[ -e "$target" ]] && ! confirm "$target" skills; then
    echo "skip $target"; continue
  fi
  rm -rf "$target"
  cp -R "$dir" "$target"
  echo "installed $target"
done

for file in "$src"/agents/*.md; do
  target="$dest/agents/$(basename "$file")"
  if [[ -e "$target" ]] && ! confirm "$target" agents; then
    echo "skip $target"; continue
  fi
  cp "$file" "$target"
  echo "installed $target"
done

(( yes )) && [[ -d "$backup" ]] && echo "Previous versions backed up to $backup"
echo "Done. Start a new Claude Code session and type /relay, /relay-os or /relay-oh."
