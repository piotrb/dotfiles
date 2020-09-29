#if [ -e ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ]; then
#  export SSH_AUTH_SOCK=~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
#else
#  if [[ $(ssh-add -l | grep -v "no identities" | wc -l) -lt 1 ]]; then
#    ssh-add -K
#  fi
#fi
