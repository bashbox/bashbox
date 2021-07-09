function subcommand::clean()
{

	print_help()
	{
		println::helpgen ${_self_name^^}-${_subcommand_argv^^} \
			--short-desc "\
${SUBCOMMANDS_DESC[3]}\
" \
	\
			--usage "\
${_self_name} $_subcommand_argv <path>\
" \
	\
			--examples "\
### The basic way:
${YELLOW}${_self_name} ${_subcommand_argv}${RC} # Cleans the project in your current directory

### Clean project from a specified directory:
${YELLOW}${_self_name} ${_subcommand_argv} /home/me/awesome_project${RC}\
"

	}

	use _clap;

	rm -r "$_target_dir";
}