function subcommand::install() {
	use box::string::trim;
	
	readonly _registry_meta_file="${_bashbox_home}/registry.meta" && touch "$_registry_meta_file";
	readonly _registry_meta_url="https://raw.githubusercontent.com/bashbox/registry/main/registry.meta";
	readonly _registry_lastsync_file="${_bashbox_home}/.registry.lastsync" && touch "$_registry_lastsync_file";

	# Repository info
	readonly _user_repo="bashbox/registry";
	readonly _check_file="registry.meta";
	readonly _branch="main";

	# Check if the registry was updated
	println::info "Syncing repository metadata";
	local _local_sha _remote_sha;
	_local_sha="$(< "$_registry_lastsync_file")";
	_remote_sha="$(curl --silent "https://api.github.com/repos/${_user_repo}/contents/${_check_file}?ref=${_branch}" \
					| head -n4 | grep -I '"sha":' | sed -E 's/.*"([^"]+)".*/\1/')";
	readonly _local_sha _remote_sha;
	
	if test "$_local_sha" != "$_remote_sha"; then {
		println::info "Updating registry.meta";
		curl --silent -o "$_registry_meta_file" -L "$_registry_meta_url";
		echo "$_remote_sha" > "$_registry_lastsync_file";
	} fi


	# Now fetch the project
	local _input _libdir;
	readonly _input="$1";
	readonly _libdir="$_bashbox_libdir/$_input";
	_tarball_download_link="$(grep ".*/$_input" "$_registry_meta_file")" || println::error "No such box as $_input was found" 1;
	readonly _tarball_download_link;

	# println::info "Installing $_input";
	if test -e "$_libdir"; then {
		rm -r "$_libdir";
	} fi
	mkdir -p "$_libdir";
	
	println::info "Downloading box $_input";
	curl --silent -L "${_tarball_download_link}/archive/refs/heads/main.tar.gz" | tar --strip-components=1 -C "$_libdir" -xpzf -;

	# Now resolve submodules if necessary
	local _gitmod_file="$_libdir/.gitmodules";

	if test -e "$_gitmod_file"; then {
		local _path _url _install_path;
		println::info "Resolving submodules";

		while read -r _line; do {
			_line="${_line%%:*}";

			_path="$(sed "${_line}q;d" "$_gitmod_file" \
				| cut -d '=' -f2 | trim_leading_trailing)";
						
			_url="$(sed "$(( _line + 1 ))q;d" "$_gitmod_file" \
				| cut -d '=' -f2 | trim_leading_trailing)";

			_install_path="${_libdir}/${_path}";			

			println::info "Downloading submodule: $_path";
			# echo "Url: $_url";
			# geco '---'
			
			if test -e "$_install_path"; then {
				rm -r "$_install_path";
				mkdir -p "$_install_path";
			} fi
			
			curl --silent -L "${_url}/archive/refs/heads/main.tar.gz" | tar --strip-components=1 -C "$_install_path" -xpzf -;

		} done < <(grep -n 'path.*=' "$_gitmod_file")
	} fi

	
	println::info "Compiling $_input in release mode";
	local _build_log && {
		_build_log="$("$___self" build "$_libdir" --release 2>&1)" \
		|| {
			geco "$_build_log";
			println::error "Errors were found while compiling $_input, operation failed" 1;
		};
	}

	local _built_executable="$_libdir/target/release/executable";
	local _install_executable="$_bashbox_bindir/$_input";

	chmod +x "$_built_executable";
	ln -srf "$_built_executable" "$_install_executable";
	chmod +x "$_install_executable";
	println::info "$_input was successfully installed";

}
