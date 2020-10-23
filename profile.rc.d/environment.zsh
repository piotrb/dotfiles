setopt NOTIFY PUSHD_TO_HOME BASH_AUTO_LIST LIST_AMBIGUOUS
setopt LONG_LIST_JOBS NO_CLOBBER
setopt PUSHD_SILENT AUTO_PUSHD PUSHD_MINUS
setopt EXTENDED_GLOB RC_QUOTES MAIL_WARNING

unsetopt BG_NICE AUTO_PARAM_SLASH MENU_COMPLETE AUTO_CD AUTO_RESUME GLOB_DOTS CORRECT CORRECT_ALL CDABLE_VARS AUTO_MENU
unsetopt REC_EXACT

unsetopt nomatch

setopt MENU_COMPLETE

# cd not select parent dir.
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# fix forward delete
bindkey "^[[3~" delete-char

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

# Repeatedly try to connect to a host which is booting
# ssh's return code is a little unhelpful as it doesn't distinguish the failure
# reason properly so this is a little naive
function try_ssh () {
	SUCCESS=0
	while [ $SUCCESS -eq 0 ]; do
		ssh -o "ConnectTimeout 30" $*
		RESULT=$?
		if [ $RESULT -ne 255 ]; then
			SUCCESS=1
		else
			echo "--> SSH return code was $RESULT"
			print "Waiting to retry ssh..."
			sleep 10
			echo "--> Retrying..."
		fi
	done
}

