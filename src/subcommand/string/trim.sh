trim_leading_trailing() {
	local _stream="${1:-}";
	local _stdin;
	if test -z "${_stream}"; then {
		read -r _stdin;
		_stream="$_stdin";
	} fi

    # remove leading whitespace characters
    _stream="${_stream#"${_stream%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    _stream="${_stream%"${_stream##*[![:space:]]}"}"
    printf '%s\n' "$_stream"
}