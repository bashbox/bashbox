coming_soon() {
	println::error "In progress, coming in one of the future updates, try again later"
}

geco() {
	echo -e "$@"
}

begins_with_short_option() {
	local first_option all_short_options='h'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}