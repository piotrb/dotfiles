if which starship 2>/dev/null 1>/dev/null; then
  eval "$(starship init zsh)"
else
  echo "starship not installed"
fi
