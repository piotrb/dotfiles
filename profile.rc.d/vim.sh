if $(command -v nvim); then
  alias vim="nvim"
  alias vimdiff="nvim -d"
else
  alias vimdiff="vim -d"
fi
