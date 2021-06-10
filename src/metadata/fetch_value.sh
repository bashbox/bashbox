metadata::fetch_value() {
	local key
	local stream
	
	key="$1"
	stream="$2"
	
	
	# If stdin
	if test -z "$stream"; then
		# If zygote_file is defined
		if test -n "$_zygote_file"; then
			stream="$(< "$_zygote_file")"
		else
			read stdin
			test -n "$stdin" && stream="$stdin" || return 1
		fi
	# If stream is a file
	elif test -f "$stream"; then
		stream="$(< "$stream")" || return 1
	fi
	
	# Ensure the stream is valid
	test -z "$stream" && return 1
	
	head -n1 < <(grep "$key=\".*\"" <<<"$stream") \
		| cut -d '"' -f2
}