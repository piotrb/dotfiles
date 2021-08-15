SSH_AGENT_MODE=Auto

function which_s() {
  env which $1 2>&1 >/dev/null && return 0 || return 1
}

function detect_mode() {
  if [ -e ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ] && [ -e /Applications/Secretive.app ]; then
    SSH_AGENT_MODE=Secretive
    return
  fi

  if which_s ssh-agent; then
    if { ssh-add -h 2>&1| grep "in your keychain" -q }; then
      SSH_AGENT_MODE=SSH-MAC
    else
      SSH_AGENT_MODE=SSH
    fi
    return
  fi

  if which_s gpg-agent; then
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
    if [ -z "$(pgrep ssh-agent)" ]; then
      rm -rf /tmp/ssh-*
      eval $(ssh-agent -s) > /dev/null
    else
      export SSH_AGENT_PID=$(pgrep ssh-agent)
      export SSH_AUTH_SOCK=$(find /tmp/ssh-* -name agent.*)
    fi

    if [[ $(ssh-add -l | grep -v "no identities" | wc -l) -lt 1 ]]; then
      ssh-add -k
    fi
    ;;
  SSH-MAC)
    if [[ $(ssh-add -l | grep -v "no identities" | wc -l) -lt 1 ]]; then
      ssh-add -A
    fi
    ;;
esac
