function subcommand::selfinstall() {
	# Locate a writable PATH
	local PATH="$_bashbox_bindir:$PATH"; # IDK
	local _path;
	while read -r _path; do {
		# Check if PATH exists and write perm is present
		if test -w "$_path"; then {
			local _target_install_dir="$_path";
			break;
		} fi
	} done < <(echo -e "${PATH//:/\\n}");

	# Check if we were able to fetch a usable installation path
	if ! test -v _target_install_dir; then {
		log::error "Failed to retrieve a usable PATH directory" 1 || exit;
	} fi

	# At this stage we are good to go
	
	## Add bashbox bindir to path
	function check_shellrc_key() {
		local _input_file="$1";
		if grep "source.*\.bashbox/env" "$_input_file" 1>/dev/null; then {
			return 0
		} else {
			return 1
		} fi
	}
	local _shellrcs=(
		"$HOME/.bashrc" # bash
		"$HOME/.kshrc" # ksh
		"$HOME/.zshrc" # zsh
		"$HOME/.config/fish/config.fish" # fish
	)
	for _shellrc in "${_shellrcs[@]}"; do {

		if test -e "$_shellrc" && ! check_shellrc_key "$_shellrc"; then {	
			case "$_shellrc" in
				"${_shellrcs[0]}" | "${_shellrcs[1]}" | "${_shellrcs[2]}") # bash, ksh, zsh
					echo "source \"$_bashbox_posix_envfile\";" >> "$_shellrc";
				;;
				"${_shellrcs[3]}") # fish
					echo "source \"$_bashbox_fish_envfile\";" >> "$_shellrc";
				;;
			esac
		
		} fi

	} done

	log::info "Installing to $_target_install_dir";

	local _target_full_path="$_target_install_dir/$___self_CODENAME";
	rm -f "$_target_full_path"; # Necessary, in case its originating from a dead symlink
	local _shebang && {
		_shebang='#!'"$(command -v env) bash";
	}
	echo "$_shebang" > "$_target_full_path";
	declare -f "${___MAIN_FUNCNAME}" >> "$_target_full_path";
	echo "${___MAIN_FUNCNAME} \"\$@\";" >> "$_target_full_path";
	chmod +x "$_target_full_path";

	log::info "Installation complete, now restart your shell and run \`$___self_CODENAME --help\` to get started";
# 	log::info "Note: You might need to restart your shell to take effect"

}
