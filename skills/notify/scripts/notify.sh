#!/usr/bin/env bash
# notify.sh "<message>" [--title T] [--subtitle S] [--image PATH] [--no-dialog] [--no-sound]
# Sends a macOS notification that stays in Notification Center, plays a sound and,
# unless turned off, shows a floating dialog. Defaults come from the config file.
set -uo pipefail

CONFIG="${CLAUDE_NOTIFY_CONFIG:-$HOME/.config/claude-notify/config}"
# Defaults (the config file can override any of them).
TITLE="Claude Code"
IMAGE=""
SOUND="Glass"            # a name from /System/Library/Sounds, or "none"
DIALOG="on"              # on | off
DIALOG_SECONDS=8         # dialog closes itself after this many seconds
NOTIFICATION="on"        # on | off
APP="$HOME/Applications/ClaudeNotify.app"
# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG"

MESSAGE="${1:-Listo}"; shift || true
SUBTITLE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --subtitle) SUBTITLE="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --no-dialog) DIALOG="off"; shift ;;
    --no-sound) SOUND="none"; shift ;;
    *) shift ;;
  esac
done
IMAGE="${IMAGE/#\~/$HOME}"

# Escape for an AppleScript string literal.
as_str() { local s="${1//\\/\\\\}"; printf '"%s"' "${s//\"/\\\"}"; }

play_here() {
  [[ "$SOUND" != "none" && -f "/System/Library/Sounds/$SOUND.aiff" ]] && (afplay "/System/Library/Sounds/$SOUND.aiff" &)
}

if [[ "$NOTIFICATION" == "on" ]]; then
  if [[ -d "$APP" ]]; then
    # The notification plays the sound itself, so it rings with the banner.
    snd="none"; [[ "$SOUND" != "none" ]] && snd="$SOUND.aiff"
    args=(--title "$TITLE" --message "$MESSAGE" --sound "$snd")
    [[ -n "$SUBTITLE" ]] && args+=(--subtitle "$SUBTITLE")
    [[ -n "$IMAGE" && -f "$IMAGE" ]] && args+=(--image "$IMAGE")
    open -g "$APP" --args "${args[@]}"
  else
    # Fallback: shows only if Script Editor is allowed in System Settings > Notifications.
    play_here
    osascript -e "display notification $(as_str "$MESSAGE") with title $(as_str "$TITLE") subtitle $(as_str "$SUBTITLE")" >/dev/null 2>&1
  fi
else
  play_here
fi

if [[ "$DIALOG" == "on" ]]; then
  icon="with icon note"
  [[ -n "$IMAGE" && -f "$IMAGE" ]] && icon="with icon (POSIX file $(as_str "$IMAGE"))"
  dtitle="$TITLE"; [[ -n "$SUBTITLE" ]] && dtitle="$TITLE · $SUBTITLE"
  (osascript -e "display dialog $(as_str "$MESSAGE") with title $(as_str "$dtitle") buttons {\"OK\"} default button \"OK\" $icon giving up after $DIALOG_SECONDS" >/dev/null 2>&1 &)
fi
exit 0
