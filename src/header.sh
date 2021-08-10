function bb_bootstrap_header() {
	function process::self::exit() {
		kill -USR1 "$___self_PID";
	}
	function log::error() {
		local _retcode="${2:-$?}";
		local _exception_line="$1";
		local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[-1]}"}";

		>&2 echo -e "[!!!] \033[1;31merror\033[0m[$_retcode]: ${_source##*/}[$BASH_LINENO]: ${BB_ERR_MSG:-"$_exception_line"}";

		if test -v BB_ERR_MSG; then {
			>&2 echo -e "STACK TRACE: (TOKEN: $_exception_line)";
            # local -i startFrom="1";
            local -i _frame=0;
            # local _stack;
            local _treestack='|--';
            local _line _caller _source;

            # while _stack="$(caller $_frame 2>&1)"; do { 
            while read -r _line _caller _source < <(caller "$_frame"); do {
                # if (( $_frame + 1 >= $startFrom ))
                # then
                    # local -a _trace=( $_stack );
                    # echo "${_treestack} ${_trace[1]} @@ ${_trace[@]:2}::${_trace[0]}";
                # fi
                >&2 echo "$_treestack ${_caller} >> ${_source##*/}::${_line}";
                _frame+=1;
                _treestack+='--';
            } done

		} fi

		return "$_retcode";
	}

	\command \unalias -a || exit; # To Make sure external aliases are not interfering.
	trap 'exit' USR1; # A workaround to properly catch error status from process substitution.
						# Eg `while read -r _bruh; do echo bruh; done < <(false)`.
	trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;

	# set -o pipefail; # To grab the last return code from a pipe.
	# set -o errexit; # To exit immadiately after trapping ERR.
	# set -o errtrace; # To detect ERR on some bash builtin commands.
	# set -o nounset; # To avoid unexpected missing variables.
	# set -o functrace; # Trap functions.
	# shopt -s inherit_errexit; # To TRAP process substitution error codes in parent. (Didnt work as I had thought...)
	# shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
	set -eEuT -o pipefail;
    shopt -s inherit_errexit expand_aliases;
}
