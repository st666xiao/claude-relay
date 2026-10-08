#!/usr/bin/env bash
# Copy claude-relay skills and agents into ~/.claude, asking before overwriting.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"

mkdir -p "$dest/skills" "$dest/agents"

confirm() {
  read -r -p "$1 already exists. Overwrite? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

for dir in "$src"/skills/*/; do
  name="$(basename "$dir")"
  target="$dest/skills/$name"
  if [[ -e "$target" ]] && ! confirm "$target"; then
    echo "skip $target"; continue
  fi
  rm -rf "$target"
  cp -R "$dir" "$target"
  echo "installed $target"
done

for file in "$src"/agents/*.md; do
  target="$dest/agents/$(basename "$file")"
  if [[ -e "$target" ]] && ! confirm "$target"; then
    echo "skip $target"; continue
  fi
  cp "$file" "$target"
  echo "installed $target"
done

echo "Done. Start a new Claude Code session and type /relay, /relay-os or /relay-oh."
