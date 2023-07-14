if [ -z ${EDITOR+x} ]; then
  export EDITOR=vim
fi

if [ -z ${GIT_EDITOR+x} ]; then
  export GIT_EDITOR=vim
fi

if [ -z ${BUNDLER_EDITOR+x} ]; then
  export BUNDLER_EDITOR=code
fi

if [ -e "/Applications/Visual Studio Code.app" ]; then 
  PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
fi

if [ -e "/Applications/Visual Studio Code - Insiders.app" ]; then
  PATH="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin:$PATH"
fi

#export EDITOR="code -w"
#export GIT_EDITOR="code -w"
