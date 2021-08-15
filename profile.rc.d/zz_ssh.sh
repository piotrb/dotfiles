SSH_AGENT_MODE=Auto

function detect_mode() {
  if [ -e ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ] && [ -e /Applications/Secretive.app ]; then
    SSH_AGENT_MODE=Secretive
    return
  fi

  if env which -s ssh-agent; then
    if { ssh-add -h 2>&1| grep "in your keychain" -q }; then
      SSH_AGENT_MODE=SSH-MAC
    else
      SSH_AGENT_MODE=SSH
    fi
    return
  fi

  if env which -s gpg-agent; then
    SSH_AGENT_MODE=GPG
    return
  fi
}

echo -n "[ssh mode: "
if [ "$SSH_AGENT_MODE" == "Auto" ]; then
  echo -n "Auto -> "
  detect_mode
fi
echo -n "${SSH_AGENT_MODE}"
echo "]"

case $SSH_AGENT_MODE in
  GPG)
    if ! `echo "BYE" | nc -U ~/.gnupg/S.gpg-agent > /dev/null`; then
      eval $(gpg-agent --daemon)
    fi

    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh
    ;;
  Secretive)
    if [ -e ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ]; then
      export SSH_AUTH_SOCK=~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
    fi
    ;;
  SSH)
    echo "Todo: how do we add all keys in openssh mode?"
    # if [[ $(ssh-add -l | grep -v "no identities" | wc -l) -lt 1 ]]; then
      # ssh-add -k
    # fi
    ;;
  SSH-MAC)
    if [[ $(ssh-add -l | grep -v "no identities" | wc -l) -lt 1 ]]; then
      ssh-add -A
    fi
    ;;
esac
