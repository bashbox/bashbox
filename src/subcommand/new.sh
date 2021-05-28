function subcommand::new()
{
	# THE DEFAULTS INITIALIZATION - POSITIONALS
	_positionals=()
	_arg_path=
	# THE DEFAULTS INITIALIZATION - OPTIONALS
	_arg_codename=
	_arg_template=


	print_help()
	{
# 		printf '%s\n' "<The general help message of my script>"
# 		printf 'Usage: %s [--codename <arg>] [--template <arg>] [-h|--help] <path>\n' "$0"
# 		printf '\t%s\n' "-h, --help: Prints help"

		println::helpgen "${_self^^}-${_subcommand_argv^^}" \
			--short-desc "\
${SUBCOMMANDS_DESC[1]}\
" \
	\
			--usage "\
${_self} ${_subcommand_argv} [OPTIONAL-OPTIONS] <path>\
" \
	\
			--options-desc "\
-c, --codename<^>Avoid directory-as-codename
-t, --template<^>core, mesa, kernel templates
-h, --help<^>Prints this help information\
" \
	\
			--examples "\
### The basic way:
${YELLOW}${_self} ${_subcommand_argv} awesome_project${RC}

### Pre-setting project codename, avoiding directory-path as codename:
${YELLOW}${_self} ${_subcommand_argv} --codename cake awesome_project${RC}

### Using a specific template for project initialization(core is default):
${YELLOW}${_self} ${_subcommand_argv} --template kernel awesome_project${RC}

### Random usage EXAMPLES just for referrence:
${YELLOW}${_self} ${_subcommand_argv} --template mesa graphics_lib
${_self} ${_subcommand_argv} --template=kernel vanilla_kernel --codename vkernel
${_self} ${_subcommand_argv} --codename=cakebaker foo/bakery${RC}\
"

	}


	parse_commandline()
	{
		_positionals_count=0
		while test $# -gt 0
		do
			_key="$1"
			case "$_key" in
				--codename|-c)
					test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
					_arg_codename="$2"
					shift
					;;
				--codename=*)
					_arg_codename="${_key##--codename=}"
					;;
				--template|-t)
					test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
					_arg_template="$2"
					shift
					;;
				--template=*)
					_arg_template="${_key##--template=}"
					;;
				-h|--help)
					print_help
					exit 0
					;;
				-h*)
					print_help
					exit 0
					;;
				*)
					_last_positional="$1"
					_positionals+=("$_last_positional")
					_positionals_count=$((_positionals_count + 1))
					;;
			esac
			shift
		done
	}


	handle_passed_args_count()
	{
		local _required_args_string="'path'"
		test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes println::error "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
		test "${_positionals_count}" -le 1 || _PRINT_HELP=yes println::error "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
	}


	assign_positional_args()
	{
		local _positional_name _shift_for=$1
		_positional_names="_arg_path "

		shift "$_shift_for"
		for _positional_name in ${_positional_names}
		do
			test $# -gt 0 || break
			eval "$_positional_name=\${1}" || println::error "Error during argument parsing." 1
			shift
		done
	}

	parse_commandline "$@"
	handle_passed_args_count
	assign_positional_args 1 "${_positionals[@]}"

# # 	: "${_arg_directory:="$PWD"}"
# # 	test ! -e "$_arg_directory" && println::error "$_arg_directory directory does not exist" 1
	
# # 	## When no codename is specified
# # 	if test -z "$_arg_codename"; then
# # 		gen_names="$(find "$_arg_directory" -maxdepth 1 -mindepth 1 -type d -name "awesome_project*" 2>/dev/null | wc -l)"
# # 		test "$gen_names" -gt 0 && : "${_arg_codename:="awesome_project$((gen_names + 1))"}" \
# # 			|| : "${_arg_codename:="awesome_project"}"
# # 	fi
	_path_codename="${_arg_path##*/}"
	## When no codename || template is specified
	: "${_arg_codename:="$_path_codename"}"
	: "${_arg_template:="core"}"
	_arg_codename="$(tr -d '[:space:]' <<<"${_arg_codename,,}")" # Make lowercase and trim whitespaces

	## When the codename dir already exists
	if test -e "$_arg_path"; then
		println::error "Destination \`$_arg_path\` already exists.\n\t  You may either remove that project dir or use a different path for setup." 1
	fi

	## Check if the $_arg_template is valid
	! echo "$_arg_template" | grep -E 'core|mesa|kernel' 1>/dev/null && {
		println::error "$_arg_template is not a valid template.\n\t  core, kernel and mesa are the valid ones, so try again." 1
	}

	## Finally setup the template as per inputs
	println::info "Setting up project at \`$_arg_path\`"
	mkdir -p "$_arg_path" || println::error "Failed to initialize the project directory"

	println::info "Using $_arg_template template"
	case "$_arg_template" in
		core)
			echo '~~~CORE_TEMPLATE_ENCODED~~~'
			;;
		mesa)
			echo '~~~MESA_TEMPLATE_ENCODED~~~'
			;;
		kernel)
			echo '~~~KERNEL_TEMPLATE_ENCODED~~~'
			;;
	esac | base64 -d | tar -C "$_arg_path" -xpzf - || { rm -r "$_arg_path"; println::error "Failed to extract $_arg_template template"; }
	find "$_arg_path" -type f -name '.keep' -exec rm {} \; || { rm -r "$_arg_path"; println::error "Failed to cleanup .keep files"; }

# 	rsync -a --exclude='.git' --exclude='.keep' "$TEMPLATES_DIR/$_arg_template/" "$PROJECTS_DIR/$_arg_codename" || exit

	println::info "Resetting CODENAME metadata to $_arg_codename on !zygote.sh"
	sed -i "s|\bCODENAME=\".*\"|CODENAME=\"$_arg_codename\"|g" "$_arg_path/"'!zygote.sh' \
		|| { rm -r "$_arg_path"; println::error 'Failed to reset CODENAME metadata on !zygote.sh'; }

	println::info "Initializing git version control for your project"
	if command -v git 1>/dev/null; then
		git init "$_arg_path" 1>/dev/null || { rm -r "$_arg_path"; println::error "Failed to initialize git at \`$_arg_path\`"; }
	else
		rm -r "$_arg_path"
		println::error "git does not seem to be available" 1
	fi
}