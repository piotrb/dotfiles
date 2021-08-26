if [ -x /usr/local/bin/brew ]; then
  . $(brew --prefix asdf)/asdf.sh
elif [ -e $HOME/.asdf/asdf.sh ]; then
  . $HOME/.asdf/asdf.sh
else
  echo "asdf not loaded"
fi

if [ ! -z "${ASDF_DIR}" ]; then
  # append completions to fpath
  fpath=(${ASDF_DIR}/completions $fpath)
  # initialise completions with ZSH's compinit
  autoload -Uz compinit
  compinit
fi
