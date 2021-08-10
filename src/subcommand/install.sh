function subcommand::install() {
	use std::string::trim;
	use std::string::matches;
	# use install.clap;

	local _arg_force=off;
	local _arg_syncmeta=off;

	# Parse additional arguments in a fast wae
	local _arg_eval;
	for _arg_eval in "force" "syncmeta"; do {
		case "$@" in
			*${_arg_eval}*)
				eval "_arg_${_arg_eval}=on";
			;;
		esac
	} done
	unset _arg_eval;
	
	local _github_api_root _registry_meta_file;
	readonly _registry_meta_file="${_bashbox_home}/registry.meta" && touch "$_registry_meta_file";
	readonly _github_api_root="https://api.github.com";

	function box::syncmeta() {
		local _registry_meta_url _registry_lastsync_file 
		readonly _registry_meta_url="https://raw.githubusercontent.com/bashbox/registry/main/registry.meta";
		readonly _registry_lastsync_file="${_bashbox_home}/.registry.lastsync" && touch "$_registry_lastsync_file";

		# Repository info
		local _user_repo _check_file _branch;
		readonly _user_repo="bashbox/registry";
		readonly _check_file="registry.meta";
		readonly _branch="main";
		
		# Internal variables
		local _lock_file="$_bashbox_home/.registry.lastdate";
		local _date && _date="$(date '+%d-%m')";

		if test "$_arg_offline" == "off"; then {
			touch "$_lock_file";
			if [ "$_arg_syncmeta" == "on" ] || [ "$(< "$_lock_file")" != "$_date" ]; then {
				echo "$_date" > "$_lock_file";

				# Check if the registry was updated
				log::info "Syncing repository metadata";
				local _local_sha _remote_sha;
				_local_sha="$(< "$_registry_lastsync_file")";
				_remote_sha="$(curl --silent "${_github_api_root}/repos/${_user_repo}/contents/${_check_file}?ref=${_branch}" \
								| head -n4 | grep -I '"sha":' | sed -E 's/.*"([^"]+)".*/\1/')";
				readonly _local_sha _remote_sha;
				
				if test "$_arg_syncmeta" == "on" || test "$_local_sha" != "$_remote_sha"; then {
					log::info "Updating registry.meta";
					curl --silent -o "$_registry_meta_file" -L "$_registry_meta_url";
					echo "$_remote_sha" > "$_registry_lastsync_file";
				} fi
				
			} fi
		} fi

	}

	function box::parsemeta() {
		local _input="$1";
		local _box_dir _box_name;
		local _repo_source _repo_url _tag_name;
		
		## Parse hook metadata and declare stuff
		IFS='|' read -r _repo_source _tag_name <<<"${_input//::/|}";
		# || log::error "Lacking proper hook information for $_hook" 1 || exit; # It might fail

		if string::matches "$_repo_source" '^file://.*'; then { # Local file path
			_box_dir="$_repo_source";
			if test ! -e "$_box_dir"; then {
				log::error "$_box_dir does not exist" 1 || process::self::exit;
			} fi
			_arg_force=off; # Ignore --force arg
			_repo_url=;
			_box_name="${_box_dir##*/}";
		} elif string::matches "$_repo_source" '^.*://.*'; then { # Custom git url
			local _repo_user _repo_name;
			_repo_url="$_repo_source";
			IFS='|' read -r _repo_user _repo_name < <(
				_user="${_repo_source%/*}" && _user="${_user##*/}";
				echo -e "${_user}|${_repo_source##*/}";
			);
			_box_dir="$_bashbox_registrydir/${_repo_user}_${_repo_name}-${_tag_name}";
			_box_name="${_repo_name}";
		} elif string::matches "$_repo_source" "[a-zA-Z0-9_]"; then { # Short repo name for registered hooks
			_repo_url="$(grep ".*/${_repo_source}$" "$_registry_meta_file")" \
			|| log::error "No such box as $_repo_source was found in the registry" 1 || process::self::exit;
			_box_dir="$_bashbox_registrydir/${_repo_source}-${_tag_name}";
			_box_name="${_repo_source##*/}";
		} fi

		# Return value
		echo "${_box_name}|${_box_dir}|${_repo_url}|${_tag_name}";
	}

	# Sync repometa file
	box::syncmeta;


	# Now fetch the project
	local _box _box_dir _gitmod_file;
	local _path _url _install_path _install_executable _built_executable;
	# local _branch_name;

	for _box in "${@}"; do {	
		
		if [[ "$_box" =~ ^-- ]]; then {
			continue;
		} fi

		local _box_name _box_dir _repo_url _tag_name;
		IFS='|' read -r _box_name _box_dir _repo_url _tag_name <<<"$(box::parsemeta "$_box")";
		
		# Set defaults for _branch_name and _tag_name if empty
		# : "${_branch_name:="main"}";
		: "${_tag_name:="HEAD"}";


		# if [ -z "$_tag_name" ]; then {
		# 	_tag_name="$(curl --silent \
		# 		"${_github_api_root}/repos/${_repo_root_link##http*github.com\/}/tags" \
		# 			| head -n3 \
		# 			| grep -m 1 -Po '"name": "\K.*?(?=")')" || { log::error "Failed to fetch latest version tag of $_repo_name" 1 || exit; }
		# } fi
		# }
		# _box_dir="$_bashbox_registrydir/${_repo_name}-${_tag_name}";

		# ~~Create~~ Export usemols.metas (INTERNAL-API)
		if test "${EXPORT_USEMOL:-}" == "true"; then {
			# echo "_usemol_${_repo_name}=${_box_dir}/src" >> "$USEMOLS_META_FILE";
			export "_usemol_${_box_name}=${_box_dir}/src";
		} fi

		# Exit function if pre-existing
		if test -e "$_box_dir"; then {
			if [ "$_arg_force" == "off" ] && [ -e "$_box_dir/$_bashbox_meta_name" ]; then {
				continue;
			} else {
				rm -rf "$_box_dir";
			} fi
		} fi
		
		mkdir -p "$_box_dir";
		
		log::info "Downloading box $_box_name $_tag_name";
		curl --silent -L "${_repo_url}/archive/${_tag_name}.tar.gz" | tar --strip-components=1 -C "$_box_dir" -xpzf -;

		# Now resolve submodules if necessary
		_gitmod_file="$_box_dir/.gitmodules";

		if test -e "$_gitmod_file"; then {
			log::info "Resolving git submodules";

			while read -r _line; do {
				_line="${_line%%:*}";

				_path="$(sed "${_line}q;d" "$_gitmod_file" \
					| cut -d '=' -f2 | trim_leading_trailing)";

				_url="$(sed "$(( _line + 1 ))q;d" "$_gitmod_file" \
					| cut -d '=' -f2 | trim_leading_trailing)";

				_install_path="${_box_dir}/${_path}";

				log::info "Downloading git submodule: $_path";
				# echo "Url: $_url";
				# echo -e '---'
				
				# if test -e "$_install_path"; then {
				# 	rm -r "$_install_path";
				 	mkdir -p "$_install_path";
				# } fi
				
				# TODO: Instead of statically getting the main branch, get the default branch.
				curl --silent -L "${_url}/archive/${_tag_name}.tar.gz" | tar --strip-components=1 -C "$_install_path" -xpzf -;

			} done < <(grep -n 'path.*=' "$_gitmod_file")
		} fi

		# Check whether a library package or executable program
		if test -e "$_box_dir/$_src_dir_name/main.sh"; then {
			log::info "Compiling $_box in release mode";
			"$___self" build --release "$_box_dir" 2>&1 \
				|| {
					log::error "Errors were found while compiling $_box, operation failed" 1 || process::self::exit;
				};

			source "$_box_dir/$_bashbox_meta_name";
			_built_executable="$_box_dir/target/release/$CODENAME";
			_install_executable="$_bashbox_bindir/$CODENAME";

			chmod +x "$_built_executable";
			ln -srf "$_built_executable" "$_install_executable";
			chmod +x "$_install_executable";
			log::info "$_box was successfully installed as $CODENAME";
		} else {
			log::info "$_box was installed as a library";
		} fi
	


	} done
}
