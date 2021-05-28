metadata::set_value() {
	local key
	local value
	local stream
	
	key="$1"
	value="$2"
	stream="${3:-"$_zygote_file"}"
	
	
	# If the key NAME exists
	if grep -q "${key}=\".*\"" "$stream"; then
		sed -i "s|${key}=\".*\"|${key}=\"${value}\"|g" "$stream"
	# And when not --- obviously
	else
		echo "${key}=${value}" >> "$stream"
	fi
}