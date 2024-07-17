#if which starship 2>/dev/null 1>/dev/null; then
#  eval "$(starship init zsh)"
#else
#  echo "starship not installed"
#fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

