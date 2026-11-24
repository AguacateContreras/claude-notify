# claude-notify for zsh: the `notify` command with tab completion of its options.
# Sourced from ~/.zshrc by `./install.sh --zsh`.
_claude_notify_bin="${${(%):-%x}:A:h}/notify"

notify() { "$_claude_notify_bin" "$@"; }

_notify_sounds() {
  local -a sounds
  sounds=(none ${${(f)"$(command ls /System/Library/Sounds 2>/dev/null)"}%.aiff})
  compadd -a sounds
}

_notify() {
  _arguments \
    '1:message: ' \
    '--title[title of the notification and the dialog]:title: ' \
    '--subtitle[subtitle, e.g. the project name]:subtitle: ' \
    '--image[image shown in the notification and the dialog]:image:_files -g "*.(png|jpg|jpeg|icns)"' \
    '--sound[system sound to play]:sound:_notify_sounds' \
    '--seconds[seconds before the dialog closes itself]:seconds: ' \
    '--no-dialog[skip the floating dialog]' \
    '--no-sound[play no sound]' \
    '(- *)--help[show the options]'
}
(( $+functions[compdef] )) && compdef _notify notify
