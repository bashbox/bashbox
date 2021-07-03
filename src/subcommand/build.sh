function subcommand::build()
{
# 	ensure::garca
	use _run_build_clap;
	
	Resolve::Colons() {
		 awk '{$1=$1;print}' <<<"$1" \
		 	| sed "s|^use box::||; s|^use ||; s|;$||; s|::|/|g; s|/\*$||"; # Swap `::` with `/` and remove [`use `, `/*` `;`] keywords
	}

	Resolve::SymbolPath() {
		local _input="$1";
		local _parent;
		_parent="$(
			if grep "^use box::" <<<"$_input" 1>/dev/null; then
				echo "$_src_dir";
			else
				echo "$PWD";
			fi
		)"
		echo "$_parent/$(Resolve::Colons "$_input")"		
	}

	Resolve::CheckNewline() {
		local _input="$1";
		if ! [[ $(tail -c1 "$_input" | wc -l) -gt 0 ]]; then {
			echo >> "$_input";
		} fi
	}

	Resolve::UseSymbols() {
		# TODO: Implement `_symbol` foce-load
		# TODO: Implement BASHBOX_LIB_PATH
		local _input="$1";
		local _parsed_input && _parsed_input="$(Resolve::Colons "$_input")";
		local _parsed_input_name="${_parsed_input##*/}" && {
			local _modname="${_parsed_input_name}";
			_parsed_input="$(sed "s|${_parsed_input_name}$|${_parsed_input_name#_}|" <<<"$_parsed_input")";
			_parsed_input="$(readlink -f "$_parsed_input")";
			unset _parsed_input_name;
		}
		local _src && {
			if grep "use box::.*" <<<"$_input" 1>/dev/null; then {
				_src="$_src_dir";
			} else {
				_src="$(readlink -f "${_parsed_input}")" && {
					# Don't strip end if is a module dir
					test ! -d "$_parsed_input" && {
						_src="${_src%/*}";
					}
				}
			} fi
		}

		# TODO: Need to write to $_used_symbols_statfile
		if test "${_modname::1}" == "_" \
		|| ! grep "^${_parsed_input}.sh$" "$_used_symbols_statfile"; then {
			(
				cd "$_src"; # Change PWD for `Resolve::SymbolPath()`

				# Handle missing symbols
				if test ! -e "${_parsed_input}.sh" && test ! -e "${_parsed_input}"; then {
					println::error "$_input is missing" 1;
				} fi

				# Handle wildcard symbol loading
				if grep '\*;$' <<<"$(awk '{$1=$1;print}' <<<"$_input")" 1>/dev/null; then {
					for _modFile in "$_src/"*; do {
						Resolve::CheckNewline "$_modFile";
						cat "$_modFile"* >> "$_src/mod.sh";
					} done
				} fi
				# Handle module directory if required
				if test ! -e "${_parsed_input}.sh" && test -d "$_parsed_input"; then {
					_parsed_input="$_parsed_input/mod"; # Redirect to the module file instead
				} fi

				geco "${RED}PWD${RC}: $PWD"; # DEBUG
				geco "${CYAN}File${RC}: ${_parsed_input}.sh"; # DEBUG

				mapfile -t _use_symbols < <(grep -E 'use .*;$' "${_parsed_input}.sh" | grep -v '#' | awk '{$1=$1;print}' || true); # Grep might fail, which is why `|| true` is necessary

				# Cycle through main.sh symbols and so on.
				: ${_last_parsed_input:="${_parsed_input}"};
				geco "${PURPLE}Caller${RC}: $_last_parsed_input\n";

				(
					for _symbol in "${_use_symbols[@]}"; do
						_last_parsed_input="${_parsed_input}";
						Resolve::UseSymbols "$_symbol";
						
					done
				)

				# Start merging process
				# File names come in reversed order
				if test "${_parsed_input}.sh" != "${_last_parsed_input}.sh"; then {
					Resolve::CheckNewline "${_parsed_input}.sh";
					sed -i -e "/$(sed 's|*|\\*|g' <<<${_input})/{r ${_parsed_input}.sh" -e 'd}' "${_last_parsed_input}.sh";
					#		TARGET-TEXT		FILE-TO-INSERT		   	INPUT-FILE
					# cat "${_parsed_input}.sh" >> "${_last_parsed_input}.sh";
				} fi
				echo "${_parsed_input}.sh" >> "$_used_symbols_statfile";
				echo "$_parsed_input.sh ++ ${_last_parsed_input}.sh($_input)";
			)
		} fi
	}

	# Source project build.sh
	if test -e "$_arg_path/build.sh"; then {
		source "$_arg_path/build.sh";
		if declare -f bashbox_before_build | head -n0; then { # Will fail without pipefail
			bashbox_before_build;
		} fi
	} fi

	# Define Vars
	Resolve::UseSymbols "$_target_workdir/main";

	# Concatinate bootstrap header to main.sh
	local _bb_bootstrap;
	_bb_bootstrap=$(declare -f bb_bootstrap_header) && {
		_bb_bootstrap="${_bb_bootstrap#*{}";
		_bb_bootstrap="${_bb_bootstrap%\}}";
	}
	local _ran="$RANDOM";
	local _tmp_bbb_path="$_target_workdir/.bb_bootstrap.$_ran";
	echo '#!'"$(command -v env) bash" > "$_tmp_bbb_path"; # Place shebang
	# Add some variables
	cat << 'EOF' >> "$_tmp_bbb_path"
_self_executable="$0";
EOF
	declare -f 'println::error'	>> "$_tmp_bbb_path"; # Concate println:error
	echo "${_bb_bootstrap}"	>> "$_tmp_bbb_path"; # Concat bootstrap
	cat "$_bashbox_meta" >> "$_tmp_bbb_path"; # Concat Bashbox.meta
	cat "$_tmp_bbb_path" "$_target_workdir/main.sh" > "$_target_workfile"; # Merge main.sh with generated script
	
	# Concat main execution call
	cat << 'EOF' >> "$_target_workfile"

main "$@";

EOF
	
	if test "$_build_variant" == "release"; then {
		local _shebang;
		local _zygote_name="main@bashbox%${_ran}";
		local _tmp_bashfmt="$_target_workdir/.bb.fmt.$_ran";
		geco "function ${_zygote_name}() {" > "$_tmp_bashfmt";
		cat "$_target_workfile" >> "$_tmp_bashfmt";
		geco "\n}" >> "$_tmp_bashfmt";
		source "$_tmp_bashfmt";

		_shebang="$(grep "#\!/.*" "$_target_workfile" | head -n1)";
		geco "$_shebang" > "$_target_workfile";
		declare -f "$_zygote_name" >> "$_target_workfile";
		geco "\n${_zygote_name} \"\$@\";" >> "$_target_workfile";
		rm "$_tmp_bashfmt";
	} fi

	rm "$_tmp_bbb_path";

	# Run build.sh after actions
	if declare -f bashbox_after_build | head -n0; then { # Will fail without pipefail
		bashbox_after_build;
	} fi

	# Make it executable by the user
	chmod +x "$_target_workfile";
	
	# Run the executable if _arg_run is passed
	if test "$_arg_run" == "on"; then {
		"$_target_workfile" "${_run_target_args[@]}";
	} fi

	# set -x
	# geco '\n------'
	# _used_symbols_arr_length="${#_used_symbols_arr[@]}";
	# # _used_symbols_times=0;
	# for _arr in "${_used_symbols_arr[@]}"; do {

	# 	while test $_used_symbols_arr_length -ne 0; do {
	# 		_used_symbols_arr_length=$((_used_symbols_arr_length - 1));
	# 		_used_symbols_times=$((_used_symbols_times + 1));
	# 		_used_symbols_times_next=$((_used_symbols_times + 1));

	# 		echo "Last: ${_used_symbols_arr[-${_used_symbols_times_next}]}"

	# 		# cat "${_used_symbols_arr[-1 -${_used_symbols_times}]}" "${_used_symbols_arr[-1]}";

	# 		break;
	# 	} done

	# } done

}
