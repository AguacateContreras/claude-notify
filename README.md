# claude-notify

A macOS notifier plus a Claude Code skill that uses it. When Claude finishes a
milestone (or gets stuck and needs you), or when any script of yours calls it, you get:

1. A **sound** (configurable).
2. A **native notification** that stays in Notification Center, with your image.
3. A **floating dialog** on top of every window that closes itself.

It has two independent parts:

- **The notifier** (`notifier/`): the `notify` command and a tiny native app. It knows
  nothing about Claude, so any shell or script can use it:
  `npm test && notify "Tests green" --subtitle my-project`.
- **The skill** (`skills/notify/SKILL.md`): plain instructions telling Claude Code to
  run `notify` at milestones.

The notification is posted by a tiny native app (`ClaudeNotify.app`, ~60 lines of
Swift) that is compiled on your Mac during install. macOS treats it as a real app, so
the notification shows up as "Claude Code" with your icon and is kept in Notification
Center. `osascript display notification` can't do that unless you grant Script Editor
notification permissions.

## Install

Needs macOS and Swift (run `xcode-select --install` if you don't have it).

```bash
git clone https://github.com/AguacateContreras/claude-notify.git ~/code/claude-notify
cd ~/code/claude-notify
./install.sh
```

That's the plain install: the bundled bell icon, and Claude notifies you when it judges
something is a milestone. Add the options you want, in any order (one per line; the last line has no `\`):

```bash
./install.sh \
  --image ~/Pictures/my-logo.png \
  --zsh \
  --everywhere
```

```text
--image <path>   Icon for the notification and the dialog: png, jpg or icns.
                 [default: the bundled bell]
--zsh            Load `notify` in ~/.zshrc with tab completion, so it works even if
                 ~/.local/bin is not in your PATH. [default: off]
--everywhere     Tell Claude, in every project, to notify you at milestones
                 (adds a block to ~/.claude/CLAUDE.md). [default: off]
```

To undo an option later: `--no-zsh`, `--not-everywhere`. To change the image, run
`./install.sh --image <path>` again. To remove everything: `./install.sh --uninstall`.

Sound, title, the floating dialog and its seconds are not install options. They live in
`~/.config/claude-notify/config` (see [Configure](#configure)), and changes there apply
to the next notification, with no reinstall.

The first time, macOS asks whether "Claude Code" may send notifications: click
**Allow**. To keep them in Notification Center, open *System Settings → Notifications →
Claude Code* and set the style to *Temporary* or *Persistent* (not *None*).

Try it:

```bash
notify "It works" --subtitle test
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
| `~/.local/bin/notify` | Symlink to `notifier/notify`: the command (add `~/.local/bin` to your PATH) |
| `~/Applications/ClaudeNotify.app` | The native notification helper |
| `~/.claude/skills/notify` | Symlink to `skills/notify` in this repo (user-level skill) |
| `~/.config/claude-notify/config` | Your settings |
| `~/.claude/CLAUDE.md` (block) | Only with `--everywhere`: the "notify me" instruction |
| `~/.zshrc` (block) | Only with `--zsh`: `notify` with tab completion |

## Update

```bash
cd ~/code/claude-notify && git pull && ./install.sh
```

The command and the skill are symlinks to this repo, so `git pull` updates them.
`./install.sh` rebuilds the app only if its code or icon changed, because every rebuild
gets a new signature and macOS may ask for the notification permission again.

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

> **Changed the image but the banner still shows the old icon?** Notification Center
> caches each app's icon and restarting it does not refresh that cache. Log out and
> back in (or restart the Mac). The dialog and the image inside the banner update at
> once; only the small app icon on the left waits for the cache. Fresh installs are
> not affected.

## The `notify` command

```text
notify "<message>" [options]

  --title T        title of the notification and the dialog
  --subtitle S     subtitle, e.g. the project name
  --image PATH     image (png/jpg/icns) for this notification; "" for none
  --sound NAME     a sound from /System/Library/Sounds (Glass, Ping, Hero...) or none
  --seconds N      seconds before the dialog closes itself
  --no-dialog      skip the floating dialog
  --no-sound       play no sound
  -h, --help       show the options
```

Options override the config for that one call. For example:

```bash
npm test && notify "Tests green" --subtitle my-project --sound Hero --no-dialog
```

### Optional: zsh integration

```bash
./install.sh --zsh
```

Adds a marked block to `~/.zshrc` that loads `notifier/notify.zsh`: `notify` works even
if `~/.local/bin` is not in your PATH, and `notify --<Tab>` completes the options
(`--sound <Tab>` lists the system sounds, `--image <Tab>` lists image files). Open a new
terminal after installing. Running it again does not add a second block. To take it out:
`./install.sh --no-zsh`.

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
      "command": "~/.local/bin/notify \"Done, your turn\" --no-dialog" }] }]
  }
}
```

## Uninstall

Removes the command, the app, the skill, your config and the optional blocks in
`~/.zshrc` and `~/.claude/CLAUDE.md` (files without the block are left untouched).
The repo folder stays.

```bash
./install.sh --uninstall
```
