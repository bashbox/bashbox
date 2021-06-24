function bb_bootstrap_header() {

	set -o pipefail; # To grab the last return code from a pipe.
	set -o errexit; # To exit immadiately after trapping ERR.
	set -o errtrace; # To detect ERR on some bash builtin commands.
	set -o nounset; # To avoid unexpected missing variables.
	shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
	alias use='BB_USE_ARGS=("$@"); BB_SOURCE="${BASH_SOURCE[0]}" __use_func'; 
	trap 'BB_ERR_SOURCE="${BASH_SOURCE[0]}" println::error "$BASH_COMMAND" $?' ERR; 
	_main_src_dir="$(dirname "$(readlink -f "$0")")"; # TODO: Needs review
	_use_calls_statfile="/tmp/.bashbox.use.calls";
	rm -f "$_use_calls_statfile" && touch "$_use_calls_statfile" || {
		println::error "Failed to create $_use_calls_statfile";
	}

}
