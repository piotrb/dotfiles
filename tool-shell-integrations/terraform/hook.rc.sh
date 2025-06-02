function tf() {
	cmd_args=( "$@" )
	tf_cmd="${MUX_TF_BASE_CMD:-terraform}"
	if [ -z "$MUX_TF_AUTH_WRAPPER" ]; then
		$tf_cmd ${cmd_args[@]}
	else
		eval $MUX_TF_AUTH_WRAPPER $tf_cmd '${cmd_args[@]}'
	fi
}
