function bb_bootstrap_header() {

	# Require at least bash 4.3
	if test "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -lt 43; then {
		printf '[!!!] \033[1;31m%s\033[0m[%s]: %s\n' ERROR 1 \
      "At least bash 4.3 is required to run this." \
      "Please upgrade bash or use the correct interpreter." \
      "If you're on MacOS, you can install latest bash using brew or nix." >&2;
		exit 1;
	} fi

	function process::self::exit() {
		local _r=$?;
		(kill -USR1 "$___self_PID" 2>/dev/null || :) & exit $_r; # In case exit fails for some reason, not efficient.
		# read -rt 3 <> <(:) || :
	}
# 	function process::self::kill() {
# 		r=$?
# 		s=$$
# # 		log::error(){
# # 		:
# # 		}; export -f log::error
# # 		trap 'log::error' ERR
# 		# exec 3>&2
# 		exec 2>/dev/null
		
# 		mapfile -t lol < /proc/$___self_PID/task/$___self_PID/children
# 		for _pid in "${lol[@]}"; do {
			
# 			if test "$_pid" -ne "$___self_PID" && test $_pid -ne $s; then {
# 				kill -9 "$_pid";
# 			} fi
# 		} done
# 		# # kill -- -$___self_PID
# 		# #TODO: I have a weird idea, maybe we can recall
# 		# trap "exit $r" ERR;
# # 		echo $xz12nfhakfjdjsnf;
# 		exit $r;
# 	}

	function process::self::forcekill() {
		kill -9 "$___self_PID" 2>/dev/null;
	}

	function log::error() {
		local _retcode="${2:-$?}";
		# local _jobs && _jobs="$(jobs -l)";
		# if [[ "$_jobs" =~ CODE=[0-9]+\ read\ -rt ]]; then {
		# 	[[ "$BASH_REMATCH" =~ [0-9]+ ]];
		# 	_final_ret="$BASH_REMATCH";
		# 	kill $(jobs -p);
		# 	return $BASH_REMATCH;
		# } fi
		# CODE=$_retcode read -rt 123 <> <(:) || : &
		local _exception_line="$1";
		local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[-1]}"}";

    function ___errmsg() {
			printf '[!!!] \033[1;31m%s\033[0m[%s]: %s\n' ERROR "$_retcode" "$@" >&2;
    }

		if [[ ! "$_exception_line" == \(*\) ]]; then {
      ___errmsg "${_source##*/}[${BASH_LINENO[0]}]: ${BB_ERR_MSG:-"$_exception_line"}";

			if test -v BB_ERR_MSG; then {
					printf "STACK TRACE: (TOKEN: %s)\n" "$_exception_line" >&2;
					# local -i startFrom="1";
					local -i _frame=0;
					# local _stack;
					local _treestack='|-';
					local _line _caller _source;

					# while _stack="$(caller $_frame 2>&1)"; do { 
					while read -r _line _caller _source < <(caller "$_frame"); do {
						# if (( $_frame + 1 >= $startFrom ))
						# then
							# local -a _trace=( $_stack );
							# echo "${_treestack} ${_trace[1]} @@ ${_trace[@]:2}::${_trace[0]}";
						# fi
						printf '%s >> %s\n' "$_treestack ${_caller}" "${_source##*/}:${_line}" >&2;
						_frame+=1;
						_treestack+='-';
					} done
			} fi
		} else {
			___errmsg "${_source##*/}[${BASH_LINENO[0]}]: SUBSHELL EXITED WITH NON-ZERO STATUS";
		} fi

		return "$_retcode";
	}

	\command unalias -a || true; # To Make sure external aliases are not interfering.

	# set -o pipefail; # To grab the last return code from a pipe.
	# set -o errexit; # To exit immadiately after trapping ERR.
	# set -o errtrace; # To detect ERR on some bash builtin commands.
	# set -o nounset; # To avoid unexpected missing variables.
	# set -o functrace; # Trap functions.
	# shopt -s inherit_errexit; # To TRAP process substitution error codes in parent. (Didnt work as I had thought...)
	# shopt -s expand_aliases; # To enable alias bash-builtin usage without interactive mode.
	set -eEuT -o pipefail;
    shopt -sq inherit_errexit expand_aliases nullglob;
	
	trap 'exit' USR1; # A workaround to properly catch error status from process substitution.
					  # Eg `while read -r _bruh; do echo bruh; done < <(false)`.
					  # Also responds to `process::self::exit()`.
	trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;
}
