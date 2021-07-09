readonly _bashbox_meta_name="Bashbox.meta";
readonly _src_dir_name="src";
readonly _bashbox_home="${HOME:-"${0%/*}"}/.bashbox" && mkdir -p "$_bashbox_home";
readonly _bashbox_libdir="$_bashbox_home/lib" && mkdir -p "$_bashbox_libdir";
readonly _bashbox_bindir="$_bashbox_home/bin" && mkdir -p "$_bashbox_bindir";
readonly SUBCOMMANDS_DESC=(
	""
	"Create a new bashbox project"
	"Directly run a bashbox project"
	"Compile a bashbox project"
	"Cleanup target/ directories"
	"Install a bashbox project from repo"
	"Install bashbox into PATH"
);