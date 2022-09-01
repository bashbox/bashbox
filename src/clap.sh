function clap() {
	# THE DEFAULTS INITIALIZATION - POSITIONALS
	# _positionals=();
	# THE DEFAULTS INITIALIZATION - OPTIONALS
	_arg_debug="off";
	_arg_release="off";
	_arg_run="off";

	parse_commandline()
	{
		_positionals_count=0;
		while test $# -gt 0; do {
			_key="$1"
			case "$_key" in
				--debug)
					_arg_debug="on";
					;;
				--release)
					_arg_release="on";
					;;
				--run)
					_arg_run="on";
					;;
				--help)
					print_help && exit 0;
					;;
				--) # Do not parse anymore if _run_target_args are found.
					return 0;
					;;
				*)
					_last_positional="$1";
					_positionals+=("$_last_positional");
					_positionals_count=$((_positionals_count + 1));
					;;
			esac
			shift
		} done
	}


	# handle_passed_args_count()
	# {
	# 	local _required_args_string="'path'";
	# 	test "${_positionals_count}" -ge 1 || log::error "Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1 || exit;
	# 	test "${_positionals_count}" -le 1 || log::error "There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1 || exit;
	# }


	# assign_positional_args()
	# {
	# 	local _positional_name _shift_for=$1;
	# 	_positional_names="_arg_path ";

	# 	shift "$_shift_for";
	# 	for _positional_name in ${_positional_names}; do {
	# 		test $# -gt 0 || break;
	# 		eval "$_positional_name=\${1}" || log::error "Error during argument parsing, possibly an Argbash bug." 1 || exit;
	# 		shift;
	# 	} done
	# }

	parse_runargs()
	{
		for _arg in "${@}"; do { 
			if test "$_arg" != '--'; then {
				shift;
			} else {
				shift; # Escapes the `--` itself.
				declare -r _run_target_args=("$@");
				break;
			} fi
		} done
	}

	parse_commandline "$@";
	# Parse _run_target_args
	parse_runargs "$@";
	# handle_passed_args_count
	# assign_positional_args 1 "${_positionals[@]}";

	function gettop() {
		# Taken from AOSP build/envsetup.sh with slight modifications
		local TOPFILE="$_bashbox_meta_name";
		local TOPDIR="$_src_dir_name";
		local TOP=;
		local T;
		if [ -n "$TOP" ] && [ -f "$TOP/$TOPFILE" ] && [ -d "$TOPFILE" ]; then {
			# The following circumlocution ensures we remove symlinks from TOP.
			(cd "$TOP"; echo "$PWD");
		} elif [ -f "$TOPFILE" ] && [ -d "$TOPDIR" ]; then {
				# The following circumlocution (repeated below as well) ensures
				# that we record the true directory name and not one that is
				# faked up with symlink names.
				echo "$PWD";
		} else {
			local HERE="$PWD";
			while [ \( ! \( -f "$TOPFILE" -a "$TOPDIR" \) \) -a \( "$PWD" != "/" \) ]; do {
				cd ..;
				T="$(readlink -f "$PWD")";
			} done
			cd "$HERE";
			if [ -f "$T/$TOPFILE" ] && [ -d "$T/$TOPDIR" ]; then {
				echo "$T";
			} fi
		} fi
	}

	: "${_arg_path:="$PWD"}";
	_arg_path="$(cd -- "$_arg_path" && pwd)"; # Pull full path
	if test ! -d "$_arg_path/$_src_dir_name" || test ! -e "$_arg_path/$_bashbox_meta_name"; then {
		_top="$(gettop)";
		if test -n "$_top"; then {
			_arg_path="$_top";
			unset _top;
		} else {
			log::error "$_arg_path is not a valid bashbox project" 1 || exit;
		} fi
	} fi

	readonly _arg_path;
	readonly _src_dir="$_arg_path/$_src_dir_name";
	readonly _target_dir="$_arg_path/target";
	readonly _target_debug_dir="$_target_dir/debug";
	readonly _bashbox_meta="$_arg_path/$_bashbox_meta_name";
	readonly _target_release_dir="$_target_dir/release";

	case "${FUNCNAME[1]}" in

		"subcommand::build" | "subcommand::run")

			# Detect the build variant
			_build_variant="$(
				if test "$_arg_release" == "on"; then {
					echo "${_target_release_dir##*/}";
				} else {
					echo "${_target_debug_dir##*/}";
				} fi
			)"; # TODO: Need to add more cases depending on args.
			readonly _build_variant;
			readonly _target_workdir="$_target_dir/$_build_variant";
			readonly _used_symbols_statfile="$_target_workdir/.used_symbols";
			readonly _compiled_mod_bundle="$_target_workdir/.lib.compiled.mod";
			
			# TODO: Decide whether to keep ignoring already loaded modules.
			# Start with creating the placeholder target dirs
			for _dir in "$_target_debug_dir" "$_target_release_dir"; do {
				mkdir -p "$_dir";
			} done

			# Check newline on meta
			# io::file::check_newline "$_bashbox_meta";

			# Merge old-new files
			cp -r "$_src_dir/". "$_target_workdir/";
			local _dest_file && while read -r _dest_file; do {
				if test ! -e "$_src_dir/${_dest_file##"$_target_workdir"}"; then {
					rm -r "$_dest_file" || rm -rf "$_dest_file";
				} fi
			} done < <(find "$_target_workdir" -type f -o -type d -empty)
			# rsync -a --delete "$_src_dir/" "$_target_workdir";
			printf '' > "$_used_symbols_statfile";

			# Load metadata
			source "$_bashbox_meta";

			# Check compatibility with bashbox
			if test -v "$_bashbox_compat_var_name"; then {
				local MIN MAX VAR_REF;
				VAR_REF="${!_bashbox_compat_var_name}";
				IFS='~' read -r MIN MAX <<<"${VAR_REF}" || true;

				# Check mandetory MIN version
				if test -n "$MIN"; then {
					if ! (( $(awk '{print ($1 <= $2)}' <<<"$MIN $___self_VERSION") )); then {
						log::error "$CODENAME requires at least bashbox $MIN" 1 || exit;
					} fi
				} else {
					log::error "MIN version is missing from $_bashbox_compat_var_name in $_bashbox_meta_name" 1 || exit;
				} fi

				# Check optional MAX version
				if test -n "$MAX"; then {
					if ! (( $(awk '{print ($1 >= $2)}' <<<"$MAX $___self_VERSION") )); then {
						log::error "$CODENAME supports bashbox upto $MAX" 1 || exit;
					} fi
				} fi
				
				unset MIN MAX VAR_REF;
			} else {
				log::error "$_bashbox_compat_var_name metadata is missing in $_bashbox_meta_name" 1 || exit;
			} fi

			# Resolve dependencies
			for _box in "${DEPENDENCIES[@]}"; do {
				EXPORT_USEMOL="true" subcommand::install "$_box";
			} done

			readonly _target_workfile="$_target_workdir/$CODENAME";
			# readonly _usemols_meta="$_target_workdir/$_usemols_meta_name";
				
			# # Now lets load the usemols in RAM
			# set -a;
			# source "$_usemols_meta";
			# set +a;
			
		;;
	esac
}