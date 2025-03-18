# if [ -x /opt/homebrew/bin/brew ]; then
#   . $(/opt/homebrew/bin/brew --prefix asdf)/libexec/asdf.sh
# elif [ -x /usr/local/bin/brew ]; then
#   . $(brew --prefix asdf)/libexec/asdf.sh
# elif [ -e $HOME/.asdf/asdf.sh ]; then
#   . $HOME/.asdf/asdf.sh
# fi

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

if [ -n "$ZSH_VERSION" ]; then
  if [ ! -z "${ASDF_DIR}" ]; then
    # append completions to fpath
    fpath=(${ASDF_DIR}/completions $fpath)
    # initialise completions with ZSH's compinit
    autoload -Uz compinit
    compinit
  fi
fi

if which asdf 1>/dev/null 2>/dev/null; then
  if [ -n "$ZSH_VERSION" ]; then
    if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc" ]; then
      source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
    fi
  fi

  if [ -n "$BASH_VERSION" ]; then
    if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc" ]; then
      source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc"
    fi
  fi
fi
