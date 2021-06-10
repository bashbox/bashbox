install::garca() {
	local num
	local install_as
	install_as="$1"
	num=$(grep -an '# GARCA'_'EMBEDED' "$0" | head -n1 | cut -d ':' -f1) && ((num++))
	tail -n +$num "$0" | gzip -c -d > "$install_as" && chmod 755 "$install_as" || return
}
