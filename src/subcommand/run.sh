
function subcommand::run() {
	
	subcommand::build --run "$@";
	return;

	print_help()
	{
		println::helpgen ${_self_name^^}-${_subcommand_argv^^} \
			--short-desc "\
${SUBCOMMANDS_DESC[2]}\
" \
	\
			--usage "\
${_self_name} ${_subcommand_argv} [OPTIONAL-OPTIONS] <path>\
" \
	\
			--options-desc "\
--release<^>Run in release mode
--debug<^>Run in debug mode(default)
--<^>Pass arguments to your compiled program
-h, --help<^>Prints this help information\
" \
	\
			--examples "\
### The basic way:
# Run the project in your current directory hierarchy in release-mode
${YELLOW}${_self_name} ${_subcommand_argv} --release${RC}

### Run project from a specified directory:
${YELLOW}${_self_name} ${_subcommand_argv} --release /home/me/awesome_project${RC}

### Pass arguments to the compiled executable
${YELLOW}${_self_name} ${_subcommand_argv} --release -- arg1 arg2 \"string arg\" and-so-on${RC}
"

	}
	


	function __use_func() {	
		# TODO: Remove fetchLib_fromPath.
		# TODO: Needs a rewrite ASAP.
		# Arguments
		for _input in "${@}"; do {
			local _input="$_input"; # We re-assign the value to prevent for-loop glob expansion on files.
			# local _input_extra_args="$BB_USE_ARGS"; # Only assign extra_args if they were actually passed.
		
			local _ref="_usemol_${_input%%::*}";
			local _src && {
				if grep "^box::.*" <<<"$_input" 1>/dev/null; then {
					_src="$_main_src_dir";
				} elif test -v "$_ref"; then {
					_src="${!_ref}";
					_input="${_input#*::}";
				} else {
					_src="$(readlink -f "${BB_SOURCE}")" && _src="${_src%/*}";
				} fi

			}
			local _parsed_input && _parsed_input="$(sed "s|box::||g; s|::|/|g" <<<"$_input")";
			local _parsed_input_name="${_parsed_input##*/}";
			_parsed_input="$(sed "s|${_parsed_input_name}$|${_parsed_input_name#_}|" <<<"$_parsed_input")";
			unset _parsed_input_name;

			# Functions
			function source_fromFile() {
				# Arguments
				local _mod="$1";
				local _modname="${_input##*::}";

				function source_call() {
					builtin source "${_mod}.sh" "${BB_USE_ARGS[@]}" || {
						log::error "Syntax/internal errors were detected in $_mod" || exit;
					}

					echo "$_mod" >> "$_used_symbols_statfile" || {
						log::error "Failed to register $_mod in log" || exit;
					}
				}

				if test "${_modname::1}" == "_"; then {
					source_call;
				} elif ! grep "^${_mod}$" "$_used_symbols_statfile" 1>/dev/null; then {
					source_call;
				} fi

			}

			function source_fromDir() {
				local _dir="$1";
				for _mod in "$_dir/"*; do {
					source_fromFile "${_mod%.sh}";
				} done
			}

			function fetchLib_fromPath() {
				local _mod="$1";
				local _paths;
				local _found_file_mods=();
				local _found_dir_mods=();

				mapfile -t _paths < <(sed 's|:|\n|g' <<<"${BASHBOX_LIB_PATH:-}");
				for _path in "${_paths[@]}"; do {
					if test -e "$_path/$_mod"; then {
						_found_file_mods+=("$_path/$_mod");
						break;
					} elif test -d "$_path/$_mod"; then {
						_found_dir_mods+=("$_path/$_mod");
						break;
					} fi
				} done

				if test -n "${_found_file_mods[*]}" || test -n "${_found_dir_mods[*]}"; then {
					for _mod in "${_found_file_mods[@]}"; do {
						source_fromFile "$_mod";
					} done

					for _mod in "${_found_dir_mods[@]}"; do {
						source_fromDir "$_mod";
					} done

					return 0
				} else {
					return 1
				} fi
			}

			# Determine how to source
			if test -e "$_src/${_parsed_input}.sh"; then { # When we have the file in module level.
				source_fromFile "$_src/${_parsed_input}";

			} elif test -e "$_src/${_parsed_input}/mod.sh"; then { # When we have mod.sh in module dir.
				source_fromFile "${_src}/${_parsed_input}/mod";

			} elif test -e "$_bashbox_registrydir/${_parsed_input}.sh"; then { # When we have in bashbox std.
				source_fromFile "$_bashbox_registrydir/${_parsed_input}";

			} elif grep '/\*$' <<<"$_parsed_input" 1>/dev/null; then { # When the input is a whole dir.
				local _dir; _dir="$(sed 's|/\*$||' <<<"$_parsed_input")";

				if test -d "$_src/$_dir"; then { # Check in module level.
					source_fromDir "$_src/$_dir";
				} elif test -d "$_bashbox_registrydir/$_dir"; then { # Check in bashbox std.
					source_fromDir "$_bashbox_registrydir/$_dir";

				# } elif fetchLib_fromPath "$_parsed_input"; then { # Try to lookup in declared LIB PATH.
				# 	true

				} else {
					log::error "No such module tree as $_input was found" || exit;
				} fi

			} else {
				log::error "No such module as $_input was found" || exit;
			} fi

		} done
		unset BB_USE_ARGS;
	}
	use clap;

	# Add some variables
	cat << 'EOF' > "$_target_workfile"
___self="$0";
EOF
	cat "$_bashbox_meta" >> "$_target_workfile";
	# Now bootstrap the initializer
	declare -f bb_bootstrap_header | tail -n +3 | head -n -1 >> "$_target_workfile";
	cat << 'EOF' >> "$_target_workfile"
	alias use='BB_USE_ARGS=("$@"); BB_SOURCE="${BASH_SOURCE[0]}" __use_func';
	_main_src_dir="$(dirname "$(readlink -f "$0")")";
	_used_symbols_statfile="$_main_src_dir/.used_symbols";
EOF
	declare -f 'log::error' >> "$_target_workfile";
	declare -f __use_func >> "$_target_workfile";
	cat "$_target_workdir/main.sh" >> "$_target_workfile";
	echo -e "\nmain \"\$@\";" >> "$_target_workfile";
	chmod +x "$_target_workfile";
	"$_target_workfile" "${_run_target_args[@]}";
}
