function subcommand::build()
{

	lockfile "build";

	print_help()
	{
		println::helpgen ${_self_name^^}-${_subcommand_argv^^} \
			--short-desc "\
${SUBCOMMANDS_DESC[3]}\
" \
	\
			--usage "\
${_self_name} ${_subcommand_argv} [OPTIONAL-OPTIONS] <path>\
" \
	\
			--options-desc "\
--release<^>Build in release mode
--debug<^>Build in debug mode(default)
--run<^>Auto-run the executable after build
--<^>Pass arguments to your compiled program
-h, --help<^>Prints this help information\
" \
	\
			--examples "\
### The basic way:
# Buld the project in your current directory hierarchy in release-mode
${YELLOW}${_self_name} ${_subcommand_argv} --release${RC}

### Build project from a specified directory:
${YELLOW}${_self_name} ${_subcommand_argv} --release /home/me/awesome_project${RC}

### Pass arguments to the compiled executable and auto-run it after build
${YELLOW}${_self_name} ${_subcommand_argv} --release --run -- arg1 arg2 \"string arg\" and-so-on${RC}
"

	}

	clap "$@";
	
	local _orig_PWD="$PWD";

	Resolve::Colons() {
		# Swap `::` with `/` and remove [`use `, `/*` `;`] keywords

		#  awk '{$1=$1;print}' <<<"$1" \
		#  	| sed "s|^use box::||; s|^use ||; s|;$||; s|::|/|g; s|/\*$||";
		
		local result="$1";
		if [[ "$result" =~ (use\ )?([^[:space:]]+)\;$ ]]; then {
			result="${BASH_REMATCH[2]//::/\/}";
			result="${result/box\//}";
			result="${result//\/\*/}";
		} fi
		printf '%s\n' "$result";
	}

	# Resolve::SymbolPath() {
	# 	local _input="$1";
	# 	if [[ "$_input" =~ ^use\ box:: ]]; then {
	# 		echo "$PWD" >/tmp/log
	# 		: "${PWD%%/src*}/src";
	# 	} else {
	# 		: "$PWD";
	# 	} fi
	# 	printf '%s\n' "$_/$(Resolve::Colons "$_input")"
	# }

	perform_task() {
		local _task="bashbox::$1";
		# if declare -f "$_task" | head -n0; then { # Will fail without pipefail
		if declare -F "$_task" 1>/dev/null; then {
			"$_task";
		} fi
	}

	Resolve::UseSymbols() {
		# TODO: Implement BASHBOX_LIB_PATH
		# TODO: This is an absolute hell, needs a rewrite.
		local _input="$1";
		local _parsed_input;
		_parsed_input="$(Resolve::Colons "$_input")";
		local _parsed_input_name="${_parsed_input##*/}" && {
			local _modname="${_parsed_input_name}";
			# _parsed_input="$(sed "s|${_parsed_input_name}$|${_parsed_input_name#_}|" <<<"$_parsed_input")";
			_parsed_input="${_parsed_input/${_parsed_input_name}/${_parsed_input_name#_}}";
			# _parsed_input="$(readlink -f "$_parsed_input")";
			unset _parsed_input_name;
		}
		local _ref="_usemol_${_parsed_input%%/*}";
		local _src && {
			if [[ "$_input" =~ use\ box:: ]]; then {
				_src="${PWD%%/src*}/src";
			} elif test -v "$_ref"; then {
				# Cache in local build registry
				local _reg_mod_path="${!_ref}";
				local _reg_mod_target="${_local_build_registrydir}/${_reg_mod_path##*/}";

				if test ! -e "$_reg_mod_target"; then {
					cp -r "$_reg_mod_path" "$_reg_mod_target";
				} fi

				_src="$_reg_mod_target/src";
				_parsed_input="${_parsed_input#*/}"; # to pop the module name (e.g. 'std/')
			} else {
				_src="$PWD";
			} fi

			_parsed_input="$_src/$_parsed_input";
		}


		# TODO: Detect whether a module is being isolated inside a function
		# if yes then we reimport it on a future call from a different module instead of blindly ignoring it.
		if test "${_modname::1}" == "_" || [[ "$_input" =~ ^[[:space:]]+use ]] \
		|| ! [[ "$(< "${_used_symbols_statfile}")" =~ "${_parsed_input}.sh" ]]; then {
			
				if test "$_arg_verbose" == "off"; then {
					echo -e "   ${BGREEN}Compiling${RC} $_modname";
				} else {
					echo -e "---------- $_modname"; # DEBUG
				} fi

				# Handle missing symbols
				# echo "Parsed_input: $_parsed_input"; # DEBUG
				if test ! -e "${_parsed_input}.sh" && test ! -e "${_parsed_input}"; then {
					# echo "$PWD"
					log::error "$_input is missing" 5 || exit;
				} fi

				# Handle wildcard symbol loading
				if [[ "$_input" =~ \*\;$ ]]; then {
					# if test -e "$_compiled_mod_bundle"; then {
					# 	rm "$_compiled_mod_bundle";
					# } fi
					printf '\n' > "$_compiled_mod_bundle.sh";
					for _modFile in "$_parsed_input/"*; do {
						# io::file::check_newline "$_modFile";
						printf '%s\n' "$(< "$modFile")" >> "$_compiled_mod_bundle";
					} done
					_parsed_input="$_compiled_mod_bundle";
				} elif test ! -e "${_parsed_input}.sh" && test -d "$_parsed_input"; then { # Handle module directory if required
					_parsed_input="$_parsed_input/mod"; # Redirect to the module file instead
				} fi

				cd "$(dirname "$_parsed_input")";

				if test "$_arg_verbose" == "on"; then {
					echo -e "${RED}PWD${RC}: $PWD"; # DEBUG
					echo -e "${CYAN}File${RC}: ${_parsed_input}.sh"; # DEBUG
				} fi

				mapfile -t _use_symbols < <(grep -w -I -x -E '^\s+use .*;$|^use .*;$' "${_parsed_input}.sh" || true); # Grep might fail, which is why `|| true` is necessary

				# Cycle through main.sh symbols and so on.
				# local _last_parsed_input;
				: ${_last_parsed_input:="${_parsed_input}"};

				if test "$_arg_verbose" == "on"; then {
					echo -e "${PURPLE}Caller${RC}: $_last_parsed_input\n";
				} fi
				
				for _symbol in "${_use_symbols[@]}"; do
					(
						_last_parsed_input="${_parsed_input}";
						Resolve::UseSymbols "$_symbol";
						
					) || exit 1
				done
			
				# Start merging process
				# File names come in reversed order
				if test "${_parsed_input}.sh" != "${_last_parsed_input}.sh"; then {
					# io::file::check_newline "${_parsed_input}.sh";
					bash -n "${_parsed_input}.sh" || log::error "Syntax errors were found" || exit 1; # Check syntax
					local _insert_stream _input_stream;
					_insert_stream=$(< "${_parsed_input}.sh");
					_input_stream=$(< "${_last_parsed_input}.sh");
					printf '%s\n' "${_input_stream/$_input/$_insert_stream}" > "${_last_parsed_input}.sh";
					unset _insert_stream _input_stream;
					# sed -i -e "/$(sed 's|*|\\*|g' <<<${_input})/{r ${_parsed_input}.sh" -e 'd}' "${_last_parsed_input}.sh";
					#		TARGET-TEXT		FILE-TO-INSERT		   	INPUT-FILE
					# cat "${_parsed_input}.sh" >> "${_last_parsed_input}.sh";

					# LOG symbol use
					printf '%s\n' "${_parsed_input}.sh" >> "$_used_symbols_statfile";
				} fi
				# if ! grep -E '\s+' <<<"$_input" 1>/dev/null; then {
				# } fi

				if test "$_arg_verbose" == "on"; then {
					echo "$_parsed_input.sh ++ ${_last_parsed_input}.sh($_input)";
				} fi
				
			
		} else {
			local _input_stream;
			_input_stream=$(< "${_last_parsed_input}.sh");
			printf '%s\n' "${_input_stream/$_input/}" > "${_last_parsed_input}.sh";
			unset _input_stream;
		} fi
	}

	# Source project build.sh if available
	if test -e "$_arg_path/build.sh"; then {
		source "$_arg_path/build.sh";
	} fi

	perform_task "build::before";

	### Main compile process
	cd "$_target_workdir";
	Resolve::UseSymbols "main";


	### After compile process
	# Concatinate bootstrap header to main.sh
	local _bb_bootstrap;
	_bb_bootstrap=$(declare -f bb_bootstrap_header) && {
		_bb_bootstrap="${_bb_bootstrap#*{}";
		_bb_bootstrap="${_bb_bootstrap%\}}";
	}

	local _ran="$RANDOM";
	local _main_funcname="main@bashbox%${_ran}";
	local _tmp_target_workfile="$_target_workdir/.${NAME}.$_ran";
	local _shebang && {
		_shebang='#!'"$(command -v env) bash";
	}

	## Initial header creation
	printf '%s\n' "$_shebang" \
					"function ${_main_funcname}() {" \
		 			"${_bb_bootstrap}" \
					'___self="$0";' \
					'___self_PID="$$";' \
					'___self_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)";' \
					"___MAIN_FUNCNAME='$_main_funcname';" > "$_tmp_target_workfile";

	# Structure Bashbox.meta variables
	while read -r _line; do {
		if [[ "$_line" =~ ^[A-Z].*= ]]; then {
			printf '%s\n' "___self_${_line}" >> "$_tmp_target_workfile";
		} else {
			printf '%s\n' "$_line" >> "$_tmp_target_workfile";
		} fi
	} done < "$_bashbox_meta" && unset _line;
	cat "$_tmp_target_workfile" "$_target_workdir/main.sh" > "$_target_workfile"; # Merge main.sh with generated script
	printf '%s\n' 'main "$@";' 'wait;' 'exit;' '}' >> "$_target_workfile"; # Add execution point for main function
	rm "$_tmp_target_workfile";

	if test "$_build_variant" == "release"; then {
		source "$_target_workfile";
		printf '%s\n' "$_shebang" > "$_target_workfile";
		declare -f "$_main_funcname" >> "$_target_workfile";
	} fi

	# Concat main execution call
	printf '%s "$@";\n' "${_main_funcname}" >> "$_target_workfile";

	# Remove any unused `use` symbol calls
	sed -i -E 's|^(\s+)?use .*;$||g' "$_target_workfile";
	
	# Run build.sh after actions
	perform_task "build::after";
	# Only keeping the below for backwards compatibility
	if declare -F "bashbox_after_build" 1>/dev/null; then { # Will fail without pipefail
		bashbox_after_build;
	} fi

	# Make it executable by the user
	chmod +x "$_target_workfile";
	
	# Print success message
	if test "$_arg_verbose" == "off"; then {
		case "$_build_variant" in
			"release") : "optimized";;
			*) : "unoptimized + debuginfo";;
		esac
		local _is_optimized="$_";

		echo -e "   ${BGREEN}Finished${RC} $_build_variant [${_is_optimized}] target(s) in ${SECONDS}s";
	} fi

	# Run the executable if _arg_run is passed
	if test "$_arg_run" == "on"; then {
		perform_task "run::before";
		cd "$_orig_PWD";
		"$_target_workfile" "${_run_target_args[@]}" || log::warn "Target executable exited with error code $?";
		perform_task "run::after";
	} fi

	# set -x
	# echo -e '\n------'
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
