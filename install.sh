#!/usr/bin/env bash
# Installs (or updates) the notifier and the Claude Code skill on this Mac.
#   ./install.sh                 install / update
#   ./install.sh --image <path>  set the image (png/jpg/icns)
#   ./install.sh --everywhere    also tell Claude, in every project, to notify you
#                                at milestones (adds a block to ~/.claude/CLAUDE.md)
#   ./install.sh --not-everywhere  remove that block again
#   ./install.sh --zsh           add `notify` with tab completion to ~/.zshrc
#   ./install.sh --no-zsh        remove it from ~/.zshrc
#   ./install.sh --uninstall     remove everything this installer added
# Flags can be combined.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
cfg_dir="$HOME/.config/claude-notify"; cfg="$cfg_dir/config"
skills="$HOME/.claude/skills"
bin="$HOME/.local/bin"

image_arg=""; everywhere=""; zsh=""; uninstall=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image_arg="${2:?--image needs a path}"; shift 2 ;;
    --everywhere) everywhere="add"; shift ;;
    --not-everywhere) everywhere="remove"; shift ;;
    --zsh) zsh="add"; shift ;;
    --no-zsh) zsh="remove"; shift ;;
    --uninstall) uninstall=1; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Marked blocks in user files, so they can be replaced or removed cleanly.
# remove_block <file> <begin> <end>
remove_block() {
  # Leave the file untouched unless the block is really there.
  [[ -f "$1" ]] && grep -qxF "$2" "$1" || return 0
  awk -v b="$2" -v e="$3" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$1" > "$1.tmp"
  # Drop the blank lines left at the end so re-adding does not pile them up.
  perl -0pe 's/\n+\z/\n/' "$1.tmp" > "$1"; rm -f "$1.tmp"
}
# add_block <file> <begin> <end> <text>: replaces any older copy instead of stacking.
add_block() {
  remove_block "$1" "$2" "$3"
  touch "$1"
  [[ -s "$1" ]] && echo >> "$1"
  printf '%s\n' "$4" >> "$1"
}

if [[ -n "$uninstall" ]]; then
  remove_block "$HOME/.claude/CLAUDE.md" "<!-- claude-notify:begin -->" "<!-- claude-notify:end -->"
  remove_block "${ZDOTDIR:-$HOME}/.zshrc" "# claude-notify:begin" "# claude-notify:end"
  rm -f "$skills/notify" "$bin/notify"
  rm -rf "$HOME/Applications/ClaudeNotify.app" "$cfg_dir"
  echo "Uninstalled. This repo folder is still here; delete it if you want."
  exit 0
fi

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }
command -v swiftc >/dev/null || { echo "Needs Swift: run  xcode-select --install"; exit 1; }

mkdir -p "$cfg_dir" "$skills" "$bin" "$HOME/Applications"
[[ -f "$cfg" ]] || cp "$repo/config.example" "$cfg"

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

# The notifier: a plain command, usable from any shell or script.
ln -sfn "$repo/notifier/notify" "$bin/notify"

# The Claude Code skill. Linked so `git pull` in this repo updates it.
if [[ -e "$skills/notify" && ! -L "$skills/notify" ]]; then
  echo "$skills/notify exists and is not a link; move it away first"; exit 1
fi
ln -sfn "$repo/skills/notify" "$skills/notify"

# Optional: a user-level instruction so Claude notifies you in every project.
claude_md="$HOME/.claude/CLAUDE.md"
md_begin="<!-- claude-notify:begin -->"; md_end="<!-- claude-notify:end -->"
if [[ "$everywhere" == "remove" ]]; then
  remove_block "$claude_md" "$md_begin" "$md_end"
  echo "Removed the claude-notify block from $claude_md"
elif [[ "$everywhere" == "add" ]]; then
  # The snippet file already carries its own markers.
  add_block "$claude_md" "$md_begin" "$md_end" "$(cat "$repo/CLAUDE.snippet.md")"
  echo "Added the claude-notify block to $claude_md"
fi

# Optional: `notify` with tab completion in zsh, even without ~/.local/bin in PATH.
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
zsh_begin="# claude-notify:begin"; zsh_end="# claude-notify:end"
if [[ "$zsh" == "remove" ]]; then
  remove_block "$zshrc" "$zsh_begin" "$zsh_end"
  echo "Removed notify from $zshrc (open a new terminal)"
elif [[ "$zsh" == "add" ]]; then
  add_block "$zshrc" "$zsh_begin" "$zsh_end" "$zsh_begin
source \"$repo/notifier/notify.zsh\"
$zsh_end"
  echo "Added notify to $zshrc (open a new terminal, then try: notify --<Tab>)"
fi

app="$HOME/Applications/ClaudeNotify.app"
app_icon="${IMAGE/#\~/$HOME}"
# No image configured: use the bundled bell so the icon never looks unfinished.
[[ -n "$app_icon" && -f "$app_icon" ]] || app_icon="$repo/assets/default-icon.png"
# Rebuild only when the code or the icon changed: every rebuild gets a new signature
# and macOS may then ask for the notification permission again.
fingerprint="$(cat "$repo/notifier/main.swift" "$repo/notifier/build.sh" "$app_icon" | shasum -a 256 | cut -d' ' -f1)"
stamp="$cfg_dir/.app-fingerprint"
if [[ ! -d "$app" || "$(cat "$stamp" 2>/dev/null)" != "$fingerprint" ]]; then
  echo "Building ClaudeNotify.app..."
  "$repo/notifier/build.sh" "$HOME/Applications" "$app_icon" >/dev/null
  echo "$fingerprint" > "$stamp"
  # Asks macOS for permission the first time: click "Allow".
  open "$app" --args --authorize
fi

cat <<MSG
Done.
- Command: $bin/notify -> $repo/notifier/notify
- App:     $app
- Config:  $cfg
- Skill:   $skills/notify -> $repo/skills/notify
If macOS asks, allow notifications for "Claude Code". To keep them in Notification
Center, set its style to "Persistent" or "Temporary" (not "None") in
System Settings > Notifications > Claude Code.
Test:  notify "It works" --subtitle test
MSG
case ":$PATH:" in *":$bin:"*) ;; *) echo "Add $bin to your PATH to run plain \`notify\`." ;; esac
