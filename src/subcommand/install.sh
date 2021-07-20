function subcommand::install() {
	use std::string::trim;

	function sync_repometa() {
		local _registry_meta_url _registry_lastsync_file 
		readonly _registry_meta_url="https://raw.githubusercontent.com/bashbox/registry/main/registry.meta";
		readonly _registry_lastsync_file="${_bashbox_home}/.registry.lastsync" && touch "$_registry_lastsync_file";

		# Repository info
		local _user_repo _check_file _branch;
		readonly _user_repo="bashbox/registry";
		readonly _check_file="registry.meta";
		readonly _branch="main";

		# Check if the registry was updated
		println::info "Syncing repository metadata";
		local _local_sha _remote_sha;
		_local_sha="$(< "$_registry_lastsync_file")";
		_remote_sha="$(curl --silent "${_github_api_root}/repos/${_user_repo}/contents/${_check_file}?ref=${_branch}" \
						| head -n4 | grep -I '"sha":' | sed -E 's/.*"([^"]+)".*/\1/')";
		readonly _local_sha _remote_sha;
		
		if test "$_local_sha" != "$_remote_sha"; then {
			println::info "Updating registry.meta";
			curl --silent -o "$_registry_meta_file" -L "$_registry_meta_url";
			echo "$_remote_sha" > "$_registry_lastsync_file";
		} fi
	}
	
	local _github_api_root _registry_meta_file;
	readonly _registry_meta_file="${_bashbox_home}/registry.meta" && touch "$_registry_meta_file";
	readonly _github_api_root="https://api.github.com";

	# Sync repometa file
	# TODO: Needs review if its working properly
	sync_repometa;


	# Now fetch the project
	local _box _box_dir _repo_root_link _gitmod_file;
	local _path _url _install_path _install_executable _built_executable;
	local _repo_name _tag_name;
	# local _branch_name;

	for _box in "${@}"; do {	

		_repo_name="${_box%%::*}";
		_repo_root_link="$(grep ".*/$_repo_name" "$_registry_meta_file")" || println::error "No such box as $_repo_name was found" 1;
		# _branch_name="${_box%::*}" && _branch_name="${_branch_name##*::}";
		echo "${_repo_root_link##https*github.com\/}";
		_tag_name="${_box##*::}" && {
			if [[ ! "$_tag_name" =~ ^[0-9]+\.[0-9]+ ]]; then {
				_tag_name="$(curl --silent \
					"${_github_api_root}/repos/${_repo_root_link##https*github.com\/}/tags" \
						| head -n3 \
						| grep -m 1 -Po '"name": "\K.*?(?=")')";
				echo "$_tag_name";
			} fi
		}
		_box_dir="$_bashbox_registrydir/${_repo_name}-${_tag_name}";

		# Exit function if pre-existing
		if test -e "$_box_dir"; then {
			if test -e "$_box_dir/$_bashbox_meta_name"; then {
				return 0;
			} else {
				rm -rf "$_box_dir";
			} fi
		} fi
		
		mkdir -p "$_box_dir";
		
		println::info "Downloading box $_repo_name $_tag_name";
		_tmp_link="${_repo_root_link}/archive/refs/tags/${_tag_name}.tar.gz";
		echo "$_tmp_link";
		curl --silent -L "$_tmp_link" | tar --strip-components=1 -C "$_box_dir" -xpzf -;

		# Now resolve submodules if necessary
		_gitmod_file="$_box_dir/.gitmodules";

		if test -e "$_gitmod_file"; then {
			println::info "Resolving submodules";

			while read -r _line; do {
				_line="${_line%%:*}";

				_path="$(sed "${_line}q;d" "$_gitmod_file" \
					| cut -d '=' -f2 | trim_leading_trailing)";

				_url="$(sed "$(( _line + 1 ))q;d" "$_gitmod_file" \
					| cut -d '=' -f2 | trim_leading_trailing)";

				_install_path="${_box_dir}/${_path}";

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

		# Check whether a library package or executable program
		if test -e "$_box_dir/$_src_dir_name/main.sh"; then {
			println::info "Compiling $_box in release mode";
			"$___self" build "$_box_dir" --release 2>&1 \
				|| {
					println::error "Errors were found while compiling $_box, operation failed" 1;
				};

			_built_executable="$_box_dir/target/release/executable";
			_install_executable="$_bashbox_bindir/$_box";

			chmod +x "$_built_executable";
			ln -srf "$_built_executable" "$_install_executable";
			chmod +x "$_install_executable";
			println::info "$_box was successfully installed";
		} else {
			println::info "$_box was installed as a library";
		} fi

	} done
}
