#!/usr/bin/env bash
# Installs (or updates) the notify skill for Claude Code on this Mac.
#   ./install.sh                 install / rebuild with the configured image
#   ./install.sh --image <path>  set the image (png/jpg/icns) and rebuild
#   ./install.sh --everywhere    also tell Claude, in every project, to notify you
#                                at milestones (adds a block to ~/.claude/CLAUDE.md)
#   ./install.sh --not-everywhere  remove that block again
# Flags can be combined.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
cfg_dir="$HOME/.config/claude-notify"; cfg="$cfg_dir/config"
skills="$HOME/.claude/skills"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }
command -v swiftc >/dev/null || { echo "Needs Swift: run  xcode-select --install"; exit 1; }

mkdir -p "$cfg_dir" "$skills" "$HOME/Applications"
[[ -f "$cfg" ]] || cp "$repo/config.example" "$cfg"

image_arg=""; everywhere=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image_arg="${2:?--image needs a path}"; shift 2 ;;
    --everywhere) everywhere="add"; shift ;;
    --not-everywhere) everywhere="remove"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -n "$image_arg" ]]; then
  img="$(cd "$(dirname "$image_arg")" && pwd)/$(basename "$image_arg")"
  [[ -f "$img" ]] || { echo "No such image: $image_arg"; exit 1; }
  # Keep a private copy so moving the original does not break it.
  cp "$img" "$cfg_dir/image.${img##*.}"
  img="$cfg_dir/image.${img##*.}"
  grep -v '^IMAGE=' "$cfg" > "$cfg.tmp"; echo "IMAGE=\"$img\"" >> "$cfg.tmp"; mv "$cfg.tmp" "$cfg"
fi

IMAGE=""; # shellcheck disable=SC1090
source "$cfg"

# Link the skill so `git pull` in this repo updates it.
if [[ -e "$skills/notify" && ! -L "$skills/notify" ]]; then
  echo "$skills/notify exists and is not a link; move it away first"; exit 1
fi
ln -sfn "$repo/skills/notify" "$skills/notify"

# Optional: a user-level instruction so Claude notifies you in every project.
claude_md="$HOME/.claude/CLAUDE.md"
begin="<!-- claude-notify:begin -->"; end="<!-- claude-notify:end -->"
remove_block() {
  [[ -f "$claude_md" ]] || return 0
  awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$claude_md" > "$claude_md.tmp"
  # Drop the blank lines left at the end so re-adding does not pile them up.
  perl -0pe 's/\n+\z/\n/' "$claude_md.tmp" > "$claude_md"; rm -f "$claude_md.tmp"
}
if [[ "$everywhere" == "remove" ]]; then
  remove_block
  echo "Removed the claude-notify block from $claude_md"
elif [[ "$everywhere" == "add" ]]; then
  remove_block   # replace any older copy instead of stacking them
  touch "$claude_md"
  [[ -s "$claude_md" ]] && echo >> "$claude_md"
  cat "$repo/CLAUDE.snippet.md" >> "$claude_md"
  echo "Added the claude-notify block to $claude_md"
fi

echo "Building ClaudeNotify.app..."
"$repo/helper/build.sh" "$HOME/Applications" "${IMAGE/#\~/$HOME}" >/dev/null
# First launch asks macOS for permission: click "Allow".
open "$HOME/Applications/ClaudeNotify.app" --args --authorize

cat <<MSG
Done.
- Skill:   $skills/notify -> $repo/skills/notify
- Config:  $cfg
- App:     ~/Applications/ClaudeNotify.app
If macOS asks, allow notifications for "Claude Code". To keep them in Notification
Center, set its style to "Persistent" or "Temporary" (not "None") in
System Settings > Notifications > Claude Code.
Test:  $skills/notify/scripts/notify.sh "It works" --subtitle test
MSG
