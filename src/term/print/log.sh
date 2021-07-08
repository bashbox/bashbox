println::info() {
	test "$_arg_quiet" == "off" && echo -e "[%%%] ${WHITE}info${RC}: $@"
}

println::warn() {
	test "$_arg_quiet" == "off" && echo -e "[***] ${YELLOW}warn${RC}: $@"
}

println::error() {
	local _return_code=${2:-$?};
	local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[0]}"}";
	local _command="$1";
	test "${_PRINT_HELP:-no}" == yes && print_help >&2

	echo -e "[!!!] \033[1;31mERROR\033[0m[$_return_code]: $_source[$BASH_LINENO]: $_command";
	case "${JOB:-"exit"}" in
		exit)
			exit $_return_code;
		;;
		kill)
			kill -9 "$BASHPID"
		;;
	esac
}
