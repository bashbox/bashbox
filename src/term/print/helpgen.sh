println::helpgen() {
	# THE DEFAULTS INITIALIZATION - POSITIONALS
	_positionals=()
	_arg_helpname=
	# THE DEFAULTS INITIALIZATION - OPTIONALS
	_arg_short_desc=
	_arg_usage=
	_arg_options_desc=
	_arg_subcommands=
	_arg_examples=
	_arg_footer_msg=

	print_help() {
		printf '%s\n' "<The general help message of my script>"
		printf 'Usage: %s [--short-desc <arg>] [--usage <arg>] [--options-desc <arg>] [--subcommands <arg>] [--examples <arg>] [--footer-msg <arg>] [-h|--help] <helpname>\n' "$0"
		printf '\t%s\n' "-h, --help: Prints help"
	}

	parse_commandline() {
		_positionals_count=0
		while test $# -gt 0; do
			_key="$1"
			case "$_key" in
			--short-desc)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_short_desc="$2"
				shift
				;;
			--short-desc=*)
				_arg_short_desc="${_key##--short-desc=}"
				;;
			--usage)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_usage="$2"
				shift
				;;
			--usage=*)
				_arg_usage="${_key##--usage=}"
				;;
			--options-desc)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_options_desc="$2"
				shift
				;;
			--options-desc=*)
				_arg_options_desc="${_key##--options-desc=}"
				;;
			--subcommands)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_subcommands="$2"
				shift
				;;
			--subcommands=*)
				_arg_subcommands="${_key##--subcommands=}"
				;;
			--examples)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_examples="$2"
				shift
				;;
			--examples=*)
				_arg_examples="${_key##--examples=}"
				;;
			--footer-msg)
				test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				_arg_footer_msg="$2"
				shift
				;;
			--footer-msg=*)
				_arg_footer_msg="${_key##--footer-msg=}"
				;;
			-h | --help)
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

	handle_passed_args_count() {
		local _required_args_string="'helpname'"
		test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes println::error "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
		test "${_positionals_count}" -le 1 || _PRINT_HELP=yes println::error "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
	}

	assign_positional_args() {
		local _positional_name _shift_for=$1
		_positional_names="_arg_helpname "

		shift "$_shift_for"
		for _positional_name in ${_positional_names}; do
			test $# -gt 0 || break
			eval "$_positional_name=\${1}" || println::error "Error during argument parsing." 1
			shift
		done
	}

	parse_commandline "$@"
	handle_passed_args_count
	assign_positional_args 1 "${_positionals[@]}"

	# Title block
	## TEXT child
	echo -e "${_arg_helpname}\c"
	if test -n "$_arg_short_desc"; then
		echo -e " - $_arg_short_desc\n"
	else
		echo # Newline space
	fi

	# Body block
	## USAGE child
	if test -n "$_arg_usage"; then
		echo -e "USAGE:"
		while read -r line; do
			echo -e "    $line"
		done < <(echo "$_arg_usage")
		echo # Newline space
	fi

	## OPTIONS+SUBCOMMANDS child
	### Column implementaion in bash without coreutils-column
	for child in "$_arg_options_desc" "$_arg_subcommands"; do
		if test -n "$child"; then
			local _startString _endString gapVar
			_startString="$(sed 's|<^>.*||g' <<<"${child}")"
			_endString="$(sed 's|.*<^>||g' <<<"${child}")"
			mapfile -t _startString < <(echo "$_startString")
			mapfile -t _endString < <(echo "$_endString")

			local i=0
			local firstChild=false;
			! "$firstChild" && echo -e "OPTIONS:" || echo -e 'SUBCOMMANDS:' && firstChild=true;

			for line in "${_startString[@]}"; do
				gapVar="$(
					for t in $(seq $((30 - ${#line}))); do
						echo -n " "
					done
				)"
				echo -e "    $line${gapVar}${_endString[$i]}"
				i=$((i+1))
			done
			echo
		fi
	done

	## EXAMPLES child
	if test -n "$_arg_examples"; then
		echo -e "EXAMPLES:"
		while read -r line; do
			echo -e "    $line"
		done < <(echo "$_arg_examples")
		echo # Newline space
	fi

	# Footer block
	## TEXT child
	if test -n "$_arg_footer_msg"; then
		echo -e "$_arg_footer_msg\n"
	fi

}
