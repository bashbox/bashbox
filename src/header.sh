function bb_bootstrap_header() {
	function log::error() {
		local _retcode="${2:-$?}";
		local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[-1]}"}";

		>&2 echo -e "[!!!] \033[1;31merror\033[0m[$_retcode]: ${_source}[$BASH_LINENO]: $1";
		return "$_retcode";
	}
	# TODO: Use `caller` builtin for stacktrace instead. (Check my saved meme notes)
	\command \trap 'log::error "$BASH_COMMAND" || exit' ERR;

	\command \unalias -a; # To Make sure external aliases are not interfering.
	set -o pipefail; # To grab the last return code from a pipe.
	set -o errexit; # To exit immadiately after trapping ERR.
	set -o errtrace; # To detect ERR on some bash builtin commands.
	set -o nounset; # To avoid unexpected missing variables.
	shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
}
