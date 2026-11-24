# claude-notify

A Claude Code skill for macOS. When Claude finishes a milestone (or gets stuck and
needs you), it lets you know with:

1. A **sound** (configurable).
2. A **native notification** that stays in Notification Center, with your image.
3. A **floating dialog** on top of every window that closes itself.

The notification is posted by a tiny native app (`ClaudeNotify.app`, ~60 lines of
Swift) that is compiled on your Mac during install. macOS treats it as a real app, so
the notification shows up as "Claude Code" with your icon and is kept in Notification
Center. `osascript display notification` can't do that unless you grant Script Editor
notification permissions.

## Install

Needs macOS and Swift (run `xcode-select --install` if you don't have it).

```bash
git clone git@github.com:AguacateContreras/claude-notify.git ~/code/claude-notify
cd ~/code/claude-notify
./install.sh --image ~/Pictures/my-logo.png   # or just ./install.sh for no image
```

The first time, macOS asks whether "Claude Code" may send notifications: click
**Allow**. To keep them in Notification Center, open *System Settings → Notifications →
Claude Code* and set the style to *Temporary* or *Persistent* (not *None*).

Try it:

```bash
~/.claude/skills/notify/scripts/notify.sh "It works" --subtitle test
```

## Optional: get notified in every project

The skill alone lets Claude *decide* when a notification is worth it, so outside a
project where you asked for it, it may not notify you on its own. If you want Claude to
always notify you at milestones, no matter which project you are in, install with:

```bash
./install.sh --everywhere
```

That adds a short, marked block (see `CLAUDE.snippet.md`) to `~/.claude/CLAUDE.md`, the
user-level instructions file Claude Code reads in every session. Running it again
replaces the block instead of adding a second one. To take it out:

```bash
./install.sh --not-everywhere
```

Claude still decides what counts as a milestone, so you are not notified after every
reply. For that, use the `Stop` hook described under *How Claude uses it*.

## Where it is installed

Everything is installed for your user, not for one project, so every Claude Code
session on this Mac can use it:

| Path | What it is |
|---|---|
| `~/.claude/skills/notify` | Symlink to `skills/notify` in this repo (user-level skill) |
| `~/Applications/ClaudeNotify.app` | The native notification helper |
| `~/.config/claude-notify/config` | Your settings |
| `~/.claude/CLAUDE.md` (block) | Only with `--everywhere`: the "notify me" instruction |

## Update

```bash
cd ~/code/claude-notify && git pull && ./install.sh
```

Because the skill is a symlink to this repo, `git pull` updates it. Running
`./install.sh` again rebuilds the app in case it changed.

## Configure

Edit `~/.config/claude-notify/config` (see `config.example`):

| Variable | What it does | Default |
|---|---|---|
| `TITLE` | Title of the notification and the dialog | `Claude Code` |
| `IMAGE` | Image (png/jpg/icns) shown in the notification and the dialog | empty: the bundled bell (`assets/default-icon.png`) is used as the icon |
| `SOUND` | A name from `/System/Library/Sounds`, or `none` | `Glass` |
| `DIALOG` | Floating dialog, `on`/`off` | `on` |
| `DIALOG_SECONDS` | Seconds before the dialog closes itself | `8` |
| `NOTIFICATION` | Notification Center notification, `on`/`off` | `on` |

To change the image, run `./install.sh --image <path>`. It copies the image into
`~/.config/claude-notify/` and updates the app icon too.

Per call: `notify.sh "<message>" [--title T] [--subtitle S] [--image P] [--no-dialog] [--no-sound]`.

## How Claude uses it

The skill (`skills/notify/SKILL.md`) tells any Claude Code that has it installed to run
it only at real milestones or when it needs you. It sends one line saying what finished,
with the project name as the subtitle. You don't need to touch `settings.json`.

Optional: if you also want a notification **every time** Claude finishes a reply, add a
`Stop` hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command",
      "command": "~/.claude/skills/notify/scripts/notify.sh \"Done, your turn\" --no-dialog" }] }]
  }
}
```

## Uninstall

```bash
./install.sh --not-everywhere   # only if you used --everywhere
rm ~/.claude/skills/notify
rm -rf ~/Applications/ClaudeNotify.app ~/.config/claude-notify
```
