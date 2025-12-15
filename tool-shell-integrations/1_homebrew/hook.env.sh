# Pass shell explicitly to avoid /bin/ps call (which fails in Cursor sandbox)
eval "$(/opt/homebrew/bin/brew shellenv $(_current_shell))"
