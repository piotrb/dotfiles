export XDG_CONFIG_HOME=$HOME/.config

alias kubectx='kubectl ctx'

# function k() {
# 	cmd_args=( "$@" )
# 	if [ -z "$MUX_TF_AUTH_WRAPPER" ]; then
# 		kubectl ${cmd_args[@]}
# 	else
# 		eval $MUX_TF_AUTH_WRAPPER kubectl '${cmd_args[@]}'
# 	fi
# }
