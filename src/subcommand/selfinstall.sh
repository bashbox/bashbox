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
	} done < <(sed 's|:|\n|g' <<<"$PATH");

	# Check if we were able to fetch a usable installation path
	if ! test -v _target_install_dir; then {
		println::error "Failed to retrieve a usable PATH directory" 1;
	} fi

	# At this stage we are good to go
	
	## Add bashbox bindir to path
	function check_shellrc_key() {
		local _input_file="$1";
		if grep "$_shellrc_key" "$_input_file" 1>/dev/null; then {
			return 0
		} else {
			return 1
		} fi
	}
	local _shellrc_key="BASHBOX_BINDIR";
	local _shellrcs=(
		"$HOME/.bashrc" # bash
		"$HOME/.zshrc" # zsh
		"$HOME/.config/fish/config.fish" # fish
	)
	for _shellrc in "${_shellrcs[@]}"; do {

		if test -e "$_shellrc" && ! check_shellrc_key "$_shellrc"; then {

			case "$_shellrc" in
				"${_shellrcs[0]}") # bash
					echo "${_shellrc_key}=\"$_bashbox_bindir\"" >> "$_shellrc";
					echo "export PATH=\"\$${_shellrc_key}:\$PATH\"" >> "$_shellrc";
					;;
				"${_shellrcs[1]}") # zsh
					echo "${_shellrc_key}=\"$_bashbox_bindir\"" >> "$_shellrc";
					echo "export PATH=\"\$${_shellrc_key}:\$PATH\"" >> "$_shellrc";
					;;
				"${_shellrcs[2]}") # fish
					echo "set ${_shellrc_key} \"$_bashbox_bindir\"" >> "$_shellrc";
					echo "set PATH \"\$${_shellrc_key}\" \"\$PATH\"" >> "$_shellrc";
					echo "export PATH" >> "$_shellrc";
					;;
			esac
		
		} fi

	} done

	println::info "Installing to $_target_install_dir";
	mv "$___self" "$_target_install_dir/${_self_name##*/}";
	chmod +x "$_target_install_dir/${_self_name##*/}";
	println::info "Installation complete, now simply run \`${_self_name##*/} --help\` to get started";

}