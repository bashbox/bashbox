function bb_bootstrap_header() {
	set -o pipefail; # To grab the last return code from a pipe.
	set -o errexit; # To exit immadiately after trapping ERR.
	set -o errtrace; # To detect ERR on some bash builtin commands.
	set -o nounset; # To avoid unexpected missing variables.
	\command \unalias -a; # To Make sure external aliases are not interfering.
	shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
	trap 'BB_ERR_SOURCE="${BASH_SOURCE[0]}" println::error "$BASH_COMMAND" $?' ERR;
}
