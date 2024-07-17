if which fzf 2>/dev/null 1>/dev/null; then
  export FZF_DEFAULT_OPTS="--height=~100%"
  eval "$(fzf --zsh)"
fi
