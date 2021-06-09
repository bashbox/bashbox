set -o pipefail; # To grab the last return code from a pipe.
set -o errtrace; # To detect ERR on some bash builtin commands.
shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
alias use='BB_SOURCE="${BASH_SOURCE[0]}" BB_USE_ARGS=$(printf '%q ' "$@") __use_func'; 
trap 'BB_ERR_SOURCE="${BASH_SOURCE[0]}" println::error "$BASH_COMMAND" $?' ERR; 
_main_src_dir="$(dirname "$(readlink -f "$0")")";
_use_calls_statfile="/tmp/.bashbox.use.calls";
rm -f "$_use_calls_statfile" && touch "$_use_calls_statfile" || {
	println::error "Failed to create $_use_calls_statfile";
}

function __use_func() {
	# Arguments
	for _input in "${@}"; do {
		local _input="$_input"; # We re-assign the value to prevent for-loop glob expansion on files.
		# local _input_extra_args="$BB_USE_ARGS"; # Only assign extra_args if they were actually passed.
		local _bashbox_std="${BASHBOX_ROOT:-"$HOME/.bashbox"}/lib/std";
		local _src && {
			if grep "^box::.*" <<<"$_input" 1>/dev/null; then {
				_src="$_main_src_dir";
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
				builtin source "${_mod}.sh" "$BB_USE_ARGS" || {
					println::error "Syntax/internal errors were detected in $_mod";
				}
			
				echo "$_mod" >> "$_use_calls_statfile" || {
					println::error "Failed to register $_mod in log";
				}
			}

			if test "${_modname::1}" == "_"; then {
				source_call;
			} elif ! grep "^${_mod}$" "$_use_calls_statfile" 1>/dev/null; then {
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
			local _found_file_mods=();
			local _found_dir_mods=();

			mapfile -t _paths < <(sed 's|:|\n|g' <<<"$BASHBOX_LIB_PATH");
			for _path in "${_paths[@]}"; do
				if test -e "$_path/$_mod"; then {
					_found_mods+=("$_path/$_mod");
				} elif test -d "$_path/$_mod"; then {
					_found_mods+=("$_path/$_mod");
				} fi
			done

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

		} elif test -e "$_bashbox_std/${_parsed_input}.sh"; then { # When we have in bashbox std.
			source_fromFile "$_bashbox_std/${_parsed_input}";

		} elif grep '/\*$' <<<"$_parsed_input" 1>/dev/null; then { # When the input is a whole dir.
			local _dir; _dir="$(sed 's|/\*$||' <<<"$_parsed_input")";

			if test -d "$_src/$_dir"; then { # Check in module level.
				source_fromDir "$_src/$_dir";
			} elif test -d "$_bashbox_std/$_dir"; then { # Check in bashbox std.
				source_fromDir "$_bashbox_std/$_dir";

			} elif fetchLib_fromPath "$_parsed_input"; then { # Try to loopup in declared LIB PATH.
				true

			} else {
				println::error "No such module tree as $_input was found";
			} fi

		} else {
			println::error "No such module as $_input was found";
		} fi

	} done
}

