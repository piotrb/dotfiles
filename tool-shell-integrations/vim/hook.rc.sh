if command -v nvim >/dev/null; then
  alias vim="nvim"
  alias vimdiff="nvim -d"
else
  alias vimdiff="vim -d"
fi

export EDITOR=vim
export GIT_EDITOR=vim
