#!/usr/bin/env bash

metadata::fetch_value() {
	local key
	local stream
	key="$1"
	stream="$2"
	
	# If stdin
	test -z "$stream" && {
		read stdin
		test -n "$stdin" && stream="$stdin" || return 1
	}
	
	# If stream is a file
	test -f "$stream" && {
		stream="$(< "$stream")" || return 1
	}
	
	grep "$key=" <<<"$stream" \
		| sed 's|.*=||; s|\b".*||' \
			| tr -d '[="=]'
}

echo 'HMM="not now"
NOT="oh no"' | metadata::fetch_value HMM
