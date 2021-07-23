readonly _bashbox_meta_name="Bashbox.meta";
readonly _src_dir_name="src";
readonly _bashbox_home="${HOME:-"${0%/*}"}/.bashbox" && mkdir -p "$_bashbox_home";
readonly _bashbox_registrydir="$_bashbox_home/registry" && mkdir -p "$_bashbox_registrydir";
readonly _bashbox_bindir="$_bashbox_home/bin" && mkdir -p "$_bashbox_bindir";
readonly _bashbox_posix_envfile="$_bashbox_home/env";
readonly _bashbox_fish_envfile="$_bashbox_home/env.fish";
readonly SUBCOMMANDS_DESC=(
	""
	"Create a new bashbox project"
	"Directly run a bashbox project"
	"Compile a bashbox project"
	"Cleanup target/ directories"
	"Install a bashbox project from repo"
	"Install bashbox into PATH"
);

# Exports
_var_exports=(
	_bashbox_registrydir
)
for _var in "${_var_exports[@]}"; do {
	export "$_var";
} done

# Create env file if missing
(
	for _envfile in "$_bashbox_posix_envfile" "$_bashbox_fish_envfile"; do {
		if test ! -e "$_envfile"; then {
			case "$_envfile" in
				"$_bashbox_posix_envfile") # bash, ksh, zsh
					echo "export PATH=\"$_bashbox_bindir:\$PATH\"" > "$_envfile";
				;;
				"$_bashbox_fish_envfile") # fish
					echo "set PATH \"$_bashbox_bindir\" \"\$PATH\" && export PATH" > "$_envfile";
				;;
			esac
		} fi
	} done
) &