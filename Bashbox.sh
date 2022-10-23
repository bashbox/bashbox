NAME="BashBox"
CODENAME="bashbox"
AUTHORS=("AXON <axonasif@gmail.com>")
VERSION="0.4.0"
DEPENDENCIES=(
	https://github.com/bashbox/std.git::62d14cb
	argbash::0.1.1
)
REPOSITORY="https://github.com/bashbox/bashbox"
BASHBOX_COMPAT="0.3.9~"

bashbox::build::after() {
	cp "$_target_workfile" "$_arg_path/$CODENAME";
	chmod +x "$_arg_path/$CODENAME";
}

# Try: bashbox pkgfun hello
pkgfun() (
	echo "$@";
)
