if [ -z ${EDITOR+x} ]; then
  export EDITOR=vim
fi

if [ -z ${GIT_EDITOR+x} ]; then
  export GIT_EDITOR=vim
fi

if [ -z ${BUNDLER_EDITOR+x} ]; then
  export BUNDLER_EDITOR=code
fi

if /usr/bin/which -s code-insiders; then
  alias code=code-insiders
fi

#export EDITOR="code -w"
#export GIT_EDITOR="code -w"
