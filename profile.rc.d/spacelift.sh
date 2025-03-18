function tf_sl_login() {
	terraform login spacelift.io
	direnv reload
}
