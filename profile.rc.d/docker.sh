alias dc="docker-compose"

if /usr/bin/which kubectl-krew 1>&2 2>/dev/null; then
  # add krew to path
  export PATH="${PATH}:${HOME}/.krew/bin"
fi

