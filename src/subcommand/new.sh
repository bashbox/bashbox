function subcommand::new()
{
	# THE DEFAULTS INITIALIZATION - POSITIONALS
	_positionals=()
	_arg_path=
	# THE DEFAULTS INITIALIZATION - OPTIONALS
	_arg_codename=
	# _arg_template=


	print_help()
	{
# 		printf '%s\n' "<The general help message of my script>"
# 		printf 'Usage: %s [--codename <arg>] [--template <arg>] [-h|--help] <path>\n' "$0"
# 		printf '\t%s\n' "-h, --help: Prints help"

		println::helpgen "${_self_name^^}-${_subcommand_argv^^}" \
			--short-desc "\
${SUBCOMMANDS_DESC[1]}\
" \
	\
			--usage "\
${_self_name} ${_subcommand_argv} [OPTIONAL-OPTIONS] <path>\
" \
	\
			--options-desc "\
-c, --codename<^>Avoid directory-as-codename
-h, --help<^>Prints this help information\
" \
	\
			--examples "\
### The basic way:
${YELLOW}${_self_name} ${_subcommand_argv} awesome_project${RC}

### Pre-setting project codename, avoiding directory-path as codename:
${YELLOW}${_self_name} ${_subcommand_argv} --codename cake awesome_project${RC}

### Using a specific template for project initialization(core is default):
${YELLOW}${_self_name} ${_subcommand_argv} --template kernel awesome_project${RC}

### Random usage EXAMPLES just for referrence:
${YELLOW}${_self_name} ${_subcommand_argv} --template mesa graphics_lib
${_self_name} ${_subcommand_argv} --template=kernel vanilla_kernel --codename vkernel
${_self_name} ${_subcommand_argv} --codename=cakebaker foo/bakery${RC}\
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
				# --template|-t)
				# 	test $# -lt 2 && println::error "Missing value for the optional argument '$_key'." 1
				# 	_arg_template="$2"
				# 	shift
				# 	;;
				# --template=*)
				# 	_arg_template="${_key##--template=}"
				# 	;;
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
	## : "${_arg_template:="core"}"
	_arg_codename="$(tr -d '[:space:]' <<<"${_arg_codename,,}")" # Make lowercase and trim whitespaces

	## When the codename dir already exists
	if test -e "$_arg_path"; then
		println::error "Destination \`$_arg_path\` already exists.\n\t  You may either remove that project dir or use a different path for setup." 1
	fi

	# ## Check if the $_arg_template is valid
	# if ! echo "$_arg_template" | grep -E 'core|mesa|kernel' 1>/dev/null; then {
	# 	println::error "$_arg_template is not a valid template.\n\t  core, kernel and mesa are the valid ones, so try again." 1
	# } fi

	## Finally setup the template as per inputs
	println::info "Setting up project at \`$_arg_path\`"
	mkdir -p "$_arg_path" || println::error "Failed to initialize the project directory"

	# Create src dir and main.sh
	mkdir -p "$_arg_path/$_src_dir_name";
	cat << 'EOF' > "$_arg_path/$_src_dir_name/main.sh"
function main() {
	echo "Hello world";
}

EOF

	cat << EOF > "$_arg_path/$_bashbox_meta_name"
NAME="$_path_codename"
CODENAME="$_arg_codename"
AUTHORS=("AXON <axonasif@gmail.com>")
VERSION="1.0"
DEPENDENCIES=()
REPOSITORY=""
EOF

# 	rsync -a --exclude='.git' --exclude='.keep' "$TEMPLATES_DIR/$_arg_template/" "$PROJECTS_DIR/$_arg_codename" || exit

	# println::info "Resetting CODENAME metadata to $_arg_codename on $_bashbox_meta_name"
	# sed -i "s|\bCODENAME=\".*\"|CODENAME=\"$_arg_codename\"|g" "$_arg_path/$_bashbox_meta_name" \
	# 	|| { rm -r "$_arg_path"; println::error "Failed to reset CODENAME metadata on $_bashbox_meta_name"; }

	println::info "Initializing git version control for your project"
	if command -v git 1>/dev/null; then
		git init "$_arg_path" 1>/dev/null || { _r=$?; rm -r "$_arg_path"; println::error "Failed to initialize git at \`$_arg_path\`" $_r; }

		# Create .gitignore
		geco '/target' > "$_arg_path/.gitignore";

	else
		rm -r "$_arg_path"
		println::error "git does not seem to be available, please install it" 1
	fi
}
