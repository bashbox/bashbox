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
		println::error "Failed to retrieve a usable PATH directory" 1;
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
					echo "source \"$bashbox_posix_envfile\";" >> "$_shellrc";
				;;
				"${_shellrcs[3]}") # fish
					echo "source \"$_bashbox_fish_envfile\";" >> "$_shellrc";
				;;
			esac
		
		} fi

	} done

	println::info "Installing to $_target_install_dir";

	local _target_full_path="$_target_install_dir/$NAME";
	local _target_funcname="${FUNCNAME[-1 + -1]}";
	echo '#!/usr/bin/env bash' > "$_target_full_path";
	declare -f "$_target_funcname" >> "$_target_full_path";
	echo "$_target_funcname \"\$@\";" >> "$_target_full_path";
	chmod +x "$_target_full_path";

	println::info "Installation complete, now restart your shell and run \`$NAME --help\` to get started";
# 	println::info "Note: You might need to restart your shell to take effect"

}
