function subcommand::build()
{
# 	ensure::garca
	
	# THE DEFAULTS INITIALIZATION - POSITIONALS
	_positionals=()
	_arg_path=
	# THE DEFAULTS INITIALIZATION - OPTIONALS
	_arg_output_directory=
	_arg_compress_level=
	_arg_compress_method=
	_arg_wizard="off"


	print_help()
	{
		println::helpgen ${_self^^}-${_subcommand_argv^^} \
			--short-desc "\
${SUBCOMMANDS_DESC[2]}\
" \
	\
			--usage "\
${_self} ${_subcommand_argv} [OPTIONAL-OPTIONS] <path>\
" \
	\
			--options-desc "\
-d, --output-directory<^>Custom build directory
-l, --compress-level<^>Custom compression level
-m, --compress-method<^>Custom compression method
-w, --wizard<^>Wizard for metadata re--initialization
-h, --help<^>Prints this help information\
" \
	\
			--examples "\
### The basic way:
${YELLOW}${_self} ${_subcommand_argv}${RC} # Builds the project in your current directory

### Build project from a specified directory:
${YELLOW}${_self} ${_subcommand_argv} /home/me/awesome_project${RC}

### Use wizard mode for metadata re--initialization
${YELLOW}${_self} ${_subcommand_argv} -w${RC}

### Random usage EXAMPLES just for referrence:
${YELLOW}${_self} ${_subcommand_argv} --wizard --compress-level=15
${_self} ${_subcommand_argv} -d \"$HOME/Downloads\" --wizard /projects/awesome_project
${_self} ${_subcommand_argv} /projects/awesome_project --wizard --output-directory \"$HOME/Downloads\" --compress-method=lzma2 -l 13${RC}\
"

	}


	parse_commandline()
	{
		_positionals_count=0
		while test $# -gt 0
		do
			_key="$1"
			case "$_key" in
				--output-directory|-d)
					test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
					_arg_output_directory="$2"
					shift
					;;
				--output-directory=*)
					_arg_output_directory="${_key##--output-directory=}"
					;;
				--compress-level)
					test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
					_arg_compress_level="$2"
					shift
					;;
				--compress-level=*)
					_arg_compress_level="${_key##--compress-level=}"
					;;
				--compress-method|-m)
					test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
					_arg_compress_method="$2"
					shift
					;;
				--compress-method=*)
					_arg_compress_method="${_key##--compress-method=}"
					;;
				--no-wizard|--wizard|-w)
					_arg_wizard="on"
					test "${1:0:5}" = "--no-" && _arg_wizard="off"
					;;
				-h|--help)
					print_help
					exit 0
					;;
				-h*)
					print_help
					exit 0
					;;
				*)
					_last_positional="$1"
					_positionals+=("$_last_positional")
					_positionals_count=$((_positionals_count + 1))
					;;
			esac
			shift
		done
	}


	handle_passed_args_count()
	{
		local _required_args_string="'path'"
		test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes println::error "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
		test "${_positionals_count}" -le 1 || _PRINT_HELP=yes println::error "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
	}


	assign_positional_args()
	{
		local _positional_name _shift_for=$1
		_positional_names="_arg_path "

		shift "$_shift_for"
		for _positional_name in ${_positional_names}
		do
			test $# -gt 0 || break
			eval "$_positional_name=\${1}" || println::error "Error during argument parsing." 1
			shift
		done
	}


	Resolve::Colons() {
		 awk '{$1=$1;print}' <<<"$1" \
		 	| sed "s|^use box::||; s|^use ||; s|;$||; s|::|/|g; s|/\*$||"; # Swap `::` with `/` and remove [`use `, `/*` `;`] keywords
	}

	Resolve::SymbolPath() {
		local _input="$1";
		local _parent;
		_parent="$(
			if grep "^use box::" <<<"$_input" 1>/dev/null; then
				echo "$_input_src_dir";
			else
				echo "$PWD";
			fi
		)"
		echo "$_parent/$(Resolve::Colons "$_input")"
	}

	Resolve::UseSymbols() {
		# TODO: Implement `_symbol` foce-load
		# TODO: Implement ignoring already loaded symbol
		# TODO: Implement `mod::` module level symbol resolving
		# TODO: Implement BASHBOX_LIB_PATH
		local _input="$1";
		local _parsed_input && _parsed_input="$(Resolve::Colons "$_input")";
		local _parsed_input_name="${_parsed_input##*/}" && {
			_parsed_input="$(sed "s|${_parsed_input_name}$|${_parsed_input_name#_}|" <<<"$_parsed_input")";
			_parsed_input="$(readlink -f "$_parsed_input")";
			unset _parsed_input_name;
		}
		local _src && {
			if grep "use box::.*" <<<"$_input" 1>/dev/null; then {
				_src="$_input_src_dir";
			} else {
				_src="$(readlink -f "${_parsed_input}")" && {
					# Don't strip end if is a module dir
					test ! -d "$_parsed_input" && {
						_src="${_src%/*}";
					}
				} 
			} fi
		}
		local _modname="${_parsed_input##*/}";

		if ! grep "^${_parsed_input}.sh$" "$_used_symbols_statfile"; then {
			(
				cd "$_src"; # Change PWD for `Resolve::SymbolPath()`

				# Handle wildcard symbol loading
				if grep '\*;$' <<<"$(awk '{$1=$1;print}' <<<"$_input")" 1>/dev/null; then {
					cat "$_src/"* > "$_src/mod.sh";
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
				test "${_parsed_input}.sh" != "${_last_parsed_input}.sh" && {
					sed -i -e "/$(sed 's|*|\\*|g' <<<${_input})/{r ${_parsed_input}.sh" -e 'd}' "${_last_parsed_input}.sh";
					#		TARGET-TEXT		FILE-TO-INSERT		   	INPUT-FILE
					# cat "${_parsed_input}.sh" >> "${_last_parsed_input}.sh";
				}
				echo "$_parsed_input.sh ++ ${_last_parsed_input}.sh($_input)";
			)
		} fi
	}

	parse_commandline "$@"
	# handle_passed_args_count
	assign_positional_args 1 "${_positionals[@]}"

	# Define Vars
	: "${_arg_path:="$PWD"}"
	_arg_path="$(readlink -f "$_arg_path")" # Pull full path
	_input_src_dir="$_arg_path/src"
	_target_dir="$_arg_path/target/debug"
	_used_symbols_statfile="$_target_dir/.used_symbols"
	

	rm -rf "$_target_dir";
	mkdir -p "$_target_dir";
	echo > "$_used_symbols_statfile";

	if test ! -d "$_input_src_dir"; then
		println::error "$_arg_path is not a valid bashbox project" 1
	fi

# 	set -x
# 	mapfile -t _use_symbols < <(grep -E '^use.*;$' "$_src_dir/main.sh")
# 	for _symbol in "${_use_symbols[@]}"; do
# 		Resolve::UseSymbols "$(Resolve::SymbolPath "$_symbol")"
# 		echo lol
# 	done

	rsync -a "$_input_src_dir/" "$_target_dir"
	_used_symbols_arr=();
	_used_symbols_times=0;
	Resolve::UseSymbols "$_target_dir/main";

	# Concatinate bootstrap header to main.sh
	local _bb_bootstrap;
	_bb_bootstrap=$(declare -f bb_bootstrap_header) && {
		_bb_bootstrap="${_bb_bootstrap#*{}";
		_bb_bootstrap="${_bb_bootstrap%\}}";
	}
	local _ran="$RANDOM";
	local _tmp_bbb_path="$_target_dir/.bb_bootstrap.$_ran";
	echo '#!'"$(command -v bash)" > "$_tmp_bbb_path";
	echo "${_bb_bootstrap}"	>> "$_tmp_bbb_path";
	cat "$_tmp_bbb_path" "$_target_dir/main.sh" > "$_target_dir/executable";
	rm "$_tmp_bbb_path";

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
