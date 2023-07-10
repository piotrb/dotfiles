alias dc="docker-compose"

if /usr/bin/which -s kubectl-krew; then
  # add krew to path
  export PATH="${PATH}:${HOME}/.krew/bin"
fi

