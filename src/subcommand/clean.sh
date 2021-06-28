function subcommand::clean()
{

	print_help()
	{
		println::helpgen ${_self^^}-${_subcommand_argv^^} \
			--short-desc "\
${SUBCOMMANDS_DESC[3]}\
" \
	\
			--usage "\
${_self} $_subcommand_argv <path>\
" \
	\
			--examples "\
### The basic way:
${YELLOW}${_self} ${_subcommand_argv}${RC} # Cleans the project in your current directory

### Clean project from a specified directory:
${YELLOW}${_self} ${_subcommand_argv} /home/me/awesome_project${RC}\
"

	}
	
	case "$1" in
		--help|-h)
			print_help
			exit 0
		;;
	esac
	
	: "${_arg_path:="${1:-"$PWD"}"}"
	test ! -e "$_arg_path/"'!zygote.sh' && {
		println::error "Could not find \`!zygote.sh\` in \`$_arg_path\`" 1
	}
	rm -rf "$PWD/"'!target' "$PWD/"'.!zygote'
}