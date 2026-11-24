#!/usr/bin/env bash
# Installs (or updates) the notify skill for Claude Code on this Mac.
#   ./install.sh                 install / rebuild with the configured image
#   ./install.sh --image <path>  set the image (png/jpg/icns) and rebuild
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
cfg_dir="$HOME/.config/claude-notify"; cfg="$cfg_dir/config"
skills="$HOME/.claude/skills"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }
command -v swiftc >/dev/null || { echo "Needs Swift: run  xcode-select --install"; exit 1; }

mkdir -p "$cfg_dir" "$skills" "$HOME/Applications"
[[ -f "$cfg" ]] || cp "$repo/config.example" "$cfg"

if [[ "${1:-}" == "--image" ]]; then
  img="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
  [[ -f "$img" ]] || { echo "No such image: $2"; exit 1; }
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
