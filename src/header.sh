function bb_bootstrap_header() {
	\command \unalias -a; # To Make sure external aliases are not interfering.
	set -o pipefail; # To grab the last return code from a pipe.
	set -o errexit; # To exit immadiately after trapping ERR.
	set -o errtrace; # To detect ERR on some bash builtin commands.
	set -o nounset; # To avoid unexpected missing variables.
	shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
	# TODO: Use `caller` builtin for stacktrace instead. (Check my saved meme notes)
	trap 'log::error "$BASH_COMMAND" || exit' ERR;
}
