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

function __use_func() {
	# Arguments
	for _input in "${@}"; do {
		local _input="$_input"; # We re-assign the value to prevent for-loop glob expansion on files.
		# local _input_extra_args="$BB_USE_ARGS"; # Only assign extra_args if they were actually passed.
		local _bashbox_std="${BASHBOX_ROOT:-"$HOME/.bashbox"}/lib/std";
		local _src && {
			if grep "^box::.*" <<<"$_input" 1>/dev/null; then {
				_src="$_main_src_dir";
			} else {
				_src="$(readlink -f "${BB_SOURCE}")" && _src="${_src%/*}";
			} fi

		}
		local _parsed_input && _parsed_input="$(sed "s|box::||g; s|::|/|g" <<<"$_input")";
		local _parsed_input_name="${_parsed_input##*/}";
		_parsed_input="$(sed "s|${_parsed_input_name}$|${_parsed_input_name#_}|" <<<"$_parsed_input")";
		unset _parsed_input_name;

		# Functions
		function source_fromFile() {
			# Arguments
			local _mod="$1";
			local _modname="${_parsed_input##*/}";

			function source_call() {
				builtin source "${_mod}.sh" "${BB_USE_ARGS[@]}" || {
					println::error "Syntax/internal errors were detected in $_mod";
				}
			
				echo "$_mod" >> "$_use_calls_statfile" || {
					println::error "Failed to register $_mod in log";
				}
			}

			if test "${_modname::1}" == "_"; then {
				source_call;
			} elif ! grep "^${_mod}$" "$_use_calls_statfile" 1>/dev/null; then {
				source_call;
			} fi

		}

		function source_fromDir() {
			local _dir="$1";
			for _mod in "$_dir/"*; do {
				source_fromFile "${_mod%.sh}";
			} done
		}

		function fetchLib_fromPath() {
			local _mod="$1";
			local _found_file_mods=();
			local _found_dir_mods=();

			mapfile -t _paths < <(sed 's|:|\n|g' <<<"$BASHBOX_LIB_PATH");
			for _path in "${_paths[@]}"; do {
				if test -e "$_path/$_mod"; then {
					_found_mods+=("$_path/$_mod");
				} elif test -d "$_path/$_mod"; then {
					_found_mods+=("$_path/$_mod");
				} fi
			} done

			if test -n "${_found_file_mods[*]}" || test -n "${_found_dir_mods[*]}"; then {
				for _mod in "${_found_file_mods[@]}"; do {
					source_fromFile "$_mod";
				} done

				for _mod in "${_found_dir_mods[@]}"; do {
					source_fromDir "$_mod";
				} done

				return 0
			} else {
				return 1
			} fi
		}

		# Determine how to source
		if test -e "$_src/${_parsed_input}.sh"; then { # When we have the file in module level.
			source_fromFile "$_src/${_parsed_input}";

		} elif test -e "$_src/${_parsed_input}/mod.sh"; then { # When we have mod.sh in module dir.
			source_fromFile "${_src}/${_parsed_input}/mod";

		} elif test -e "$_bashbox_std/${_parsed_input}.sh"; then { # When we have in bashbox std.
			source_fromFile "$_bashbox_std/${_parsed_input}";

		} elif grep '/\*$' <<<"$_parsed_input" 1>/dev/null; then { # When the input is a whole dir.
			local _dir; _dir="$(sed 's|/\*$||' <<<"$_parsed_input")";

			if test -d "$_src/$_dir"; then { # Check in module level.
				source_fromDir "$_src/$_dir";
			} elif test -d "$_bashbox_std/$_dir"; then { # Check in bashbox std.
				source_fromDir "$_bashbox_std/$_dir";

			} elif fetchLib_fromPath "$_parsed_input"; then { # Try to loopup in declared LIB PATH.
				true

			} else {
				println::error "No such module tree as $_input was found";
			} fi

		} else {
			println::error "No such module as $_input was found";
		} fi

	} done
	unset BB_USE_ARGS;
}

#!/usr/bin/env bash
source "${0%/*}/init.sh" || exit

#####################
### Public functions
#####################
use println::*;
use utils;
use term::colors;
# use install::garca;
# use ensure::garca;
# use metadata::fetch_value;
# use metadata::set_value;

#####################
### Private functions
#####################
use subcommand;

function print_help() {
	println::helpgen "${_self^^}" \
		--short-desc "\
GearLock Development Kit\
" \
		\
		--usage "\
${_self} [OPTIONAL-OPTIONS] [SUBCOMMAND] <subcommand-arguments>\
" \
		\
		--options-desc "\
-V, --version<^>Print version info and exit
-v, --verbose<^>Use very verbose output
-q, --quiet<^>No output printed to stdout
--offline<^>Run without checking for update
-h, --help<^>Prints this help information\
" \
		\
		--subcommands "\
new<^>${SUBCOMMANDS_DESC[1]}
build<^>${SUBCOMMANDS_DESC[2]}
clean<^>${SUBCOMMANDS_DESC[3]}
extract<^>${SUBCOMMANDS_DESC[4]}
install<^>${SUBCOMMANDS_DESC[5]}
metadata<^>${SUBCOMMANDS_DESC[6]}\
" \
		\
		--footer-msg "\
Try 'gdk <subcommand> --help' for more information on a specific command.
For bugreports: https://github.com/gearlock-users-repo/issues\
";
}

function main() {
	#####################
	### Initialization
	#####################
	### Constants
	# GCOMM="gearlock"
	# PS3="$(echo -e "\nEnter a number >> ")"
	readonly VERSION="0.1.0";
	readonly SUBCOMMANDS_DESC=(
		""
		"Create a new gxp project"
		"Compile the targetted project"
		"Cleanup build directories"
		"Extract a gxp to target dir"
		"Install gdk onto PATH"
		"Fetch metadata of a gxp"
	);

	### Mutables
	_self="${0##*/}";
	_selfDir="$(dirname "$(readlink -f "$0")")";
	_arg_verbose=off;
	_arg_quiet=off;
	_arg_offline=off;

	#####################
	### Start of arg parse
	#####################

	# Assign optional parent arguments
	for arg in "${@}"; do
		case "$arg" in
			--verbose | -v)
				_arg_verbose=on;
				;;
			--quiet | -q)
				_arg_quiet=on;
				;;
			--offline)
				_arg_offline=on;
				;;
			--version | -V)
				echo "$VERSION";
				exit 0;
				;;
			--help | -h*)
				test "$arg" == "$1" && print_help && exit 0;
				;;
		esac
	done

	# Drop/escape optional parent arguments
	for i in $(
		a=$#;
		until test $a -eq 0; do
			echo $a;
			((a--));
		done
	); do
		eval "echo \$$i" | grep -E 'verbose|quiet|offline' 1>/dev/null && {
			set -- "${@:1:$i-1}" "${@:$i+1}";
		}
	done
	# TODO(LESSON): Dynamic argument parsing on bash is a nightmare. Well, at least for me on this script.

	#####################
	### Setup options
	#####################
	## Verbose
	test "$_arg_verbose" == on && test "$_arg_quiet" == off && {
		set -x;
	}

	#####################
	### Main execution
	#####################
	_subcommand_argv="$1" && shift || true;
	case "$_subcommand_argv" in
		run | new | build | clean | metadata)
			subcommand::$_subcommand_argv "$@";
			;;
		*)
			test -n "$_subcommand_argv" && println::warn "Unknown subcommand: $_subcommand_argv";
			print_help;
			test -n "$_subcommand_argv" && exit 1 || exit 0;
			;;
	esac

	exit;
}

main "$@"
#!/usr/bin/bash
_out=out.shc
echo > out.shc
while read -r line; do
	if grep -E '.*;$' <<<"$line" 1>/dev/null; then
		echo -n "$line" >> "$_out"
	else
		echo "$line" >> "$_out"
	fi
done < $1
coming_soon() {
	println::error "In progress, coming in one of the future updates, try again later"
	echo "nah"
}

geco() {
	echo -e "$@"
}

begins_with_short_option() {
	local first_option all_short_options='h'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}
