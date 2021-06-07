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
		sed "s|^use box::||; s|^use ||; s|;$||; s|::|/|g; s|/\*$||" <<<"$1"; # Swap `::` with `/` and remove [`use `, `/*` `;`] keywords.
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

	Resolve::UseSymbols() {

		local _dir;
		local _file;
		local _use_symbols;
		local _symbol;
		local _symbol_name;

		_dir="$(dirname "$(readlink -f "$1")")";
		_file="$(sed "s|$_dir/||" <<<"$1").sh";
		_symbol_name="${file%.sh}";

		echo "$_symbol_name" >> "$_used_symbols_statfile" || exit
		cd "$_dir"; # Change PWD for `Resolve::SymbolPath()`

		echo "PWD: $PWD"; # DEBUG
		echo "File: $_file"; # DEBUG

		mapfile -t _use_symbols < <(grep -E '^use.*;$' "$_file");

		# Cycle through main.sh symbols
		for _symbol in "${_use_symbols[@]}"; do
			hmm="$(Resolve::SymbolPath "$_symbol")";
			echo "Symbol :$hmm"; # DEBUG
			Resolve::UseSymbols "$hmm";
		done

		echo "$_file";

<< ///
		# Cycle through the current symbol
		for _symbol in "${_use_symbols[@]}"; do
			# If the input symbol is a dir then source all files
			if test -d "$_file"; then
				for f in "$_file"/*; do
					echo -e '\n' >> "$_target_dir/dump"
					cat "$f" >> "$_target_dir/dump"
					echo -e '\n' >> "$_target_dir/dump"
				done
			else
				echo -e '\n' >> "$_target_dir/dump"
				cat "$_file" >> "$_target_dir/dump"
				echo -e '\n' >> "$_target_dir/dump"
			fi

			sed -i -e "/$(sed 's|/|\\\/|g' <<<"$_symbol")/{r $_target_dir/dump" -e 'd}' "$_target_dir/dump" \
				|| println::error "Failed to insert into $_file"

		done
///


	}

	parse_commandline "$@"
	# handle_passed_args_count
	assign_positional_args 1 "${_positionals[@]}"

	# Define Vars
	: "${_arg_path:="$PWD"}"
	_arg_path="$(readlink -f "$_arg_path")" # Pull full path
	_src_dir="$_arg_path/src"
	_target_dir="$_arg_path/target"
	_used_symbols_statfile="$_target_dir/.used_symbols"

	mkdir -p "$_target_dir" || exit
	rm -f "$_used_symbols_statfile" || exit

	if test ! -d "$_src_dir"; then
		println::error "$_arg_path is not a valid bashbox project" 1
	fi

# 	set -x
# 	mapfile -t _use_symbols < <(grep -E '^use.*;$' "$_src_dir/main.sh")
# 	for _symbol in "${_use_symbols[@]}"; do
# 		Resolve::UseSymbols "$(Resolve::SymbolPath "$_symbol")"
# 		echo lol
# 	done

	rsync -a --delete "$_src_dir/" "$_target_dir"

	Resolve::UseSymbols "$_target_dir/main"
}
