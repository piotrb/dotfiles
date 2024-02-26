if [ -x /opt/homebrew/bin/brew ]; then
  . $(/opt/homebrew/bin/brew --prefix asdf)/libexec/asdf.sh
elif [ -x /usr/local/bin/brew ]; then
  . $(brew --prefix asdf)/libexec/asdf.sh
elif [ -e $HOME/.asdf/asdf.sh ]; then
  . $HOME/.asdf/asdf.sh
fi

if [ -n "$ZSH_VERSION" ]; then
  if [ ! -z "${ASDF_DIR}" ]; then
    # append completions to fpath
    fpath=(${ASDF_DIR}/completions $fpath)
    # initialise completions with ZSH's compinit
    autoload -Uz compinit
    compinit
  fi
fi

if [ -n "$ZSH_VERSION" ]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
fi

if [ -n "$BASH_VERSION" ]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc"
fi
