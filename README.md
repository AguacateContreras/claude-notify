# claude-notify

Skill de Claude Code para macOS: cuando Claude termina un milestone (o se atora y te
necesita) te avisa con:

1. **Sonido** (configurable).
2. **Notificación nativa** que se queda en el Centro de Notificaciones, con tu imagen.
3. **Diálogo flotante** encima de todas las ventanas, que se cierra solo.

La notificación la manda un mini app nativo (`ClaudeNotify.app`, Swift, ~60 líneas) que
se compila en tu Mac al instalar. Así macOS la trata como app propia: aparece como
"Claude Code", con tu ícono, y se guarda en el stack de notificaciones (cosa que
`osascript display notification` no hace sin darle permisos a Script Editor).

## Instalar

Requiere macOS y Swift (`xcode-select --install` si no lo tienes).

```bash
git clone git@github.com:AguacateContreras/claude-notify.git ~/code/claude-notify
cd ~/code/claude-notify
./install.sh --image ~/Pictures/mi-logo.png   # o ./install.sh sin imagen
```

La primera vez macOS pregunta si "Claude Code" puede mandar notificaciones: **Permitir**.
Para que se queden en el stack, en *Ajustes del Sistema → Notificaciones → Claude Code*
el estilo debe ser *Temporal* o *Persistente* (no *Ninguno*).

Probar:

```bash
~/.claude/skills/notify/scripts/notify.sh "Ya quedó" --subtitle prueba
```

## Actualizar

```bash
cd ~/code/claude-notify && git pull && ./install.sh
```

La skill es un symlink a este repo, así que `git pull` la actualiza; `./install.sh`
recompila el app por si cambió.

## Configurar

`~/.config/claude-notify/config` (ver `config.example`):

| Variable | Qué hace | Default |
|---|---|---|
| `TITLE` | Título de la notificación y del diálogo | `Claude Code` |
| `IMAGE` | Imagen (png/jpg/icns) en la notificación y el diálogo | vacío |
| `SOUND` | Nombre en `/System/Library/Sounds` o `none` | `Glass` |
| `DIALOG` | Diálogo flotante `on`/`off` | `on` |
| `DIALOG_SECONDS` | Segundos antes de que el diálogo se cierre solo | `8` |
| `NOTIFICATION` | Notificación en el Centro de Notificaciones `on`/`off` | `on` |

Cambiar la imagen: `./install.sh --image <ruta>` (copia la imagen a
`~/.config/claude-notify/` y actualiza también el ícono del app).

Por llamada: `notify.sh "<mensaje>" [--title T] [--subtitle S] [--image P] [--no-dialog] [--no-sound]`.

## Cómo lo usa Claude

La skill (`skills/notify/SKILL.md`) le dice a cualquier Claude Code que la tenga
instalada que la corra solo en milestones reales o cuando te necesita, con una línea
que diga qué terminó y el nombre del proyecto como subtítulo. No hace falta tocar el
`settings.json`.

Opcional, si además quieres aviso **cada vez** que Claude termina de responder, agrega
un hook `Stop` en `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command",
      "command": "~/.claude/skills/notify/scripts/notify.sh \"Terminé, te toca\" --no-dialog" }] }]
  }
}
```

## Desinstalar

```bash
rm ~/.claude/skills/notify
rm -rf ~/Applications/ClaudeNotify.app ~/.config/claude-notify
```
