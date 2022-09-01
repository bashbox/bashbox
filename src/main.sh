# Bootstrap
use header;
# Unset self Bashbox.meta hooks
unset -f bashbox::build::before bashbox::build::after bashbox::run::before bashbox::run::after;
#####################
### Public functions
#####################
use variables;
# use utils;
use std::print::log;
use std::print::helpgen;
use std::term::colors;
use std::io::file::check_newline;
use argbash::common;
### Private functions
#####################
use subcommand;
use clap;

function print_help() {


	println::helpgen "${_self_name^^}" \
		--short-desc "\
Wannabe bash compiler\
" \
		\
		--usage "\
${_self_name} [OPTIONAL-OPTIONS] [SUBCOMMAND] <subcommand-arguments>\
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
install<^>${SUBCOMMANDS_DESC[4]}
selfinstall<^>${SUBCOMMANDS_DESC[5]}\
" \
		\
		--footer-msg "\
Try '${_self_name} <subcommand> --help' for more information on a specific command.
For bugreports: $___self_REPOSITORY\
";

}

function main() {
	#####################
	### Initialization
	#####################

	### Mutables
	_self_name="${___self##*/}";
	_arg_verbose=off;
	_arg_quiet=off;
	_arg_offline=off;

	#####################
	### Start of arg parse
	#####################

	# Assign optional parent arguments
	# Drop/escape optional parent arguments
	# TODO: Needs review and improvement
	for _arg in "${@}"; do {
		# Doesnt contain `--`` and is a whole word with leading `-`
		if test "$_arg" != "--" && [[ "$_arg" =~ (-|--)[a-z]+? ]]; then {
			case "$_arg" in
				# --)
				# 	break;
				# 	;;
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
					echo "$___self_VERSION";
					exit 0;
					;;
				--help | -h*)
					print_help; exit 0;
					;;
				-C)
					_arg_path="$2";
					shift;
					;;
			esac
			shift;
		} else {
			break;
		} fi
	} done
	unset _arg;

	# for i in $(
	# 	a=$#;
	# 	until test $a -eq 0; do
	# 		echo $a;
	# 		((a--));
	# 	done
	# ); do {
	# 	echo "$i"
	# 	eval "echo \$$i" | grep -E 'verbose|quiet|offline' 1>/dev/null && {
	# 		set -- "${@:1:$i-1}" "${@:$i+1}";
	# 	}
	# } done
	# unset i;
	# TODO(LESSON): Dynamic argument parsing on bash is a nightmare. Well, at least for me on this script.

	#####################
	### Setup options
	#####################
	## Verbose
	# test "$_arg_verbose" == on && test "$_arg_quiet" == off && {
		# set -x;
	# }

	#####################
	### Main execution
	#####################
	_subcommand_argv="${1:-}" && shift || true;
	case "$_subcommand_argv" in
		new | run | build | clean | install | selfinstall)
			subcommand::$_subcommand_argv "$@";
			;;
		*)
			## Check for Bashbox.sh custom user functions
			clap "$@";
			source "$_bashbox_meta";

			if declare -F "$_subcommand_argv" 1>/dev/null; then {
				("$_subcommand_argv" "$@") || log::error "$_subcommand_argv exited with errors" || :;
			} else {
				if test -n "$_subcommand_argv"; then {
					log::warn "Unknown subcommand: $_subcommand_argv";
				} fi
				print_help;

				if test -n "$_subcommand_argv"; then {
					exit 1;
				} else {
					exit 0;
				} fi
			} fi

			;;
	esac

	exit;
}
