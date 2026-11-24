---
name: notify
description: Tell the user on their Mac when a milestone is done or when you are blocked and need them. Plays a sound, posts a notification that stays in Notification Center and shows a floating dialog that closes itself. Use at real milestones (a feature finished, tests green after a long run, a deploy done, a question only the user can answer), not after every step. Also use when the user says "avísame", "notify me", "let me know when it's done".
---

# notify

The user works in other windows, so terminal output goes unseen. When a milestone
finishes or you need them, run:

```bash
~/.local/bin/notify "<one line: what finished or what you need>" --subtitle "<project name>"
```

- One short line, in the user's language. Say what is done or what you need, not how.
- `--subtitle` is the project or repo name (basename of the working directory is fine).
- Optional: `--title T`, `--image /path/to.png` (overrides the configured image for
  this one call), `--sound NAME`, `--seconds N`, `--no-dialog`, `--no-sound`.
  `notify --help` lists them.
- Run it only at real milestones and when blocked. Never in a loop, never per step.
- The script returns at once; it never blocks your work.
- If the Bash sandbox blocks it (nothing appears), rerun with the sandbox disabled;
  it only talks to macOS notification services.

`notify` is a standalone command from the claude-notify repo (it does not depend on
Claude). Configuration lives in `~/.config/claude-notify/config` (title, image, sound, dialog
on/off, dialog seconds). Do not edit it unless the user asks; to change the image the
user runs `install.sh --image <path>` from the repo, which also refreshes the app icon.
