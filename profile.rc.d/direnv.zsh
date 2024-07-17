if which direnv 2>/dev/null 1>/dev/null; then
	emulate zsh -c "$(direnv hook zsh)"
	export POWERLEVEL9K_INSTANT_PROMPT=quiet
else
  echo "direnv not installed"
fi
