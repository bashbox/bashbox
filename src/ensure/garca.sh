
ensure::garca() {
	command -v garca 1>/dev/null \
		|| { println::error "garca not found, please run \`${_self} install\` first" 1; }
}