if which direnv 2>/dev/null 1>/dev/null; then
  eval "$(direnv hook zsh)"
else
  echo "direnv not installed"
fi
