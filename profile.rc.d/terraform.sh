#!/bin/bash - 

function tf() {
	set -x
	cmd_args=( "$@" )
	if [ -z "$MUX_TF_AUTH_WRAPPER" ]; then
		terraform ${cmd_args[@]}
	else
		eval $MUX_TF_AUTH_WRAPPER terraform '${cmd_args[@]}'
	fi
}

