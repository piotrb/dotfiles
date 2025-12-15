# zmodload zsh/zprof
source ~/.antidote/antidote.zsh

antidote load

unset ZSH_AUTOSUGGEST_USE_ASYNC

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


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
