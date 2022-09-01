function subcommand::selfinstall() {
	# Locate a writable PATH
	# local PATH="$_bashbox_bindir:$PATH"; # IDK
	local _path _paths;
	local _target_install_dir
	IFS=':' read -ra _paths <<<"$PATH"
	for _path in "${_paths[@]}"; do {
		# Check if PATH exists and write perm is present
		if test -w "$_path"; then {
			_target_install_dir="$_path";
			break;
		} fi
	} done

	# Check if we were able to fetch a usable installation path
	if ! test -v _target_install_dir; then {
		log::warn "Failed to retrieve a writable existing PATH directory";
		log::info "Falling back to $_bashbox_bindir";
		_target_install_dir="$_bashbox_bindir" && local _self_created_path=true;
	} fi

	# At this stage we are good to go
	
	## Add bashbox bindir to path
	function check_shellrc_key() {
		local _input_file="$1";
		grep -q "source.*\.bashbox/env" "$_input_file" 2>/dev/null;
	}
	local _shellrcs=(
		"$HOME/.bashrc" # bash
		"$HOME/.kshrc" # ksh
		"$HOME/.zshrc" # zsh
		"$HOME/.config/fish/config.fish" # fish
	)
	for _shellrc in "${_shellrcs[@]}"; do {

		if ! check_shellrc_key "$_shellrc"; then {	
			mkdir -p "${_shellrc%/*}";
			case "$_shellrc" in
				"${_shellrcs[0]}" | "${_shellrcs[1]}" | "${_shellrcs[2]}") # bash, ksh, zsh
					printf 'source "%s";\n' "$_bashbox_posix_envfile" >> "$_shellrc";
				;;
				"${_shellrcs[3]}") # fish
					printf 'source "%s";\n' "$_bashbox_fish_envfile" >> "$_shellrc";
				;;
			esac
		} fi

	} done

	log::info "Installing to $_target_install_dir";

	local _target_full_path="$_target_install_dir/$___self_CODENAME";
	rm -f "$_target_full_path"; # Necessary, in case its originating from a dead symlink
	local _shebang && _shebang='#!'"$(command -v env) bash";
	printf '%s\n' "$_shebang" \
					"$(declare -f "${___MAIN_FUNCNAME}")" \
					"${___MAIN_FUNCNAME}"' "$@";' > "$_target_full_path";
	chmod +x "$_target_full_path";

	if test -v _self_created_path; then {
		log::info "Restart your shell to update PATH env for bashbox";
	} fi
	log::info "Installation complete, run \`$___self_CODENAME --help\` to get started";
}
