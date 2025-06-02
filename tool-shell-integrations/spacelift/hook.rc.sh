function tf_sl_login() {
	tofu login spacelift.io
	direnv reload
}
alias tofu_sl_login=tf_sl_login
alias spacelift_tofu_login=tf_sl_login
