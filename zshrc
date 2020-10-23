# zmodload zsh/zprof
source ~/.antigen/source/antigen.zsh

export RBENV_ROOT=~/.rbenv

antigen init "$HOME/.antigenrc"

# load global rc scripts

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.(zsh|sh); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# load profile scripts
if [ -d $HOME/.profile.rc.d ]; then
  for i in $HOME/.profile.rc.d/*.(zsh|sh); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
