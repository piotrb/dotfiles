if [ -z ${EDITOR+x} ]; then
  export EDITOR=vim
fi

if [ -z ${GIT_EDITOR+x} ]; then
  export GIT_EDITOR=vim
fi

if [ -z ${BUNDLER_EDITOR+x} ]; then
  export BUNDLER_EDITOR=code
fi

#export EDITOR="code -w"
#export GIT_EDITOR="code -w"
