# Bootstrap
use header;
#####################
### Public functions
#####################
use variables;
use utils;
use term::print::*;
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
Wannabe bash compiler\
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
	# Drop/escape optional parent arguments
	# TODO: Needs review and improvement
	for _arg in "${@}"; do {
		# Doesnt contain `--`` and is a whole word with leading `-`
		if test "$_arg" != "--" && grep -E '\-\w+' <<<"$_arg" 1>/dev/null; then {
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
					echo "$VERSION";
					exit 0;
					;;
				--help | -h*)
					print_help && exit 0;
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
	test "$_arg_verbose" == on && test "$_arg_quiet" == off && {
		set -x;
	}

	#####################
	### Main execution
	#####################
	_subcommand_argv="${1:-}" && shift || true;
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
