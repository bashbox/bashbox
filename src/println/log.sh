println::info() {
	test "$_arg_quiet" == "off" && echo -e "[%%%] ${WHITE}info${RC}: $@"
}

println::warn() {
	test "$_arg_quiet" == "off" && echo -e "[***] ${YELLOW}warn${RC}: $@"
}

println::error() {
	local _ret="${2:-$?}"
	test "${_PRINT_HELP:-no}" == yes && print_help >&2
	echo -e "[!!!] ${BRED}error${RC}[$_ret]: $1" >&2
	exit "${_ret}"
}