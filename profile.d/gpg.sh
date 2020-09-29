#!/bin/bash -

if ! `echo "BYE" | nc -U ~/.gnupg/S.gpg-agent > /dev/null`; then
  eval $(gpg-agent --daemon)
fi

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh
