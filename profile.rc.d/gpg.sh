#!/bin/bash -

#if ! `echo "BYE" | nc -U ~/.gnupg/S.gpg-agent > /dev/null`; then
#  eval $(gpg-agent --daemon)
#fi

# todo: XDG_RUNTIME_DIR can contain an alternate user
#       socket dir and then the socket will be in that
#       plus /gnupg/ .. ie: ${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent

#export GPG_TTY=$(tty)
#export SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh
