self_update_check() {
	# TODO: Add gitlab provider.
	# Arguments
	local _provider="$1";
	local _user_repo="$2";
	local _branch="$3"
	local _check_file="$4";
	## Escape all positional arguments
	for i in {1..4}; do {
		shift
	} done

	# Internal variables
	local _lock_file="${GTMP:-"/tmp"}/gdk.update.lock";
	local _date;
	local _sha;

	_date="$(date '+%d-%m')" || return;
	_sha="$(sha256sum "$0")" || return;

	test "$_arg_offline" == "off" && {
		touch "$_lock_file" || return;
		test "$(< "$_lock_file")" != "$_date" && {
			echo "$_date" > "$_lock_file";
			test -z "$NO_PULL" && {
				println::info "Fetching update information from $_provider";
				# Close stream on 4th line
				test "$_sha" != "$(curl --silent \
									"https://api.github.com/repos/${_user_repo}/contents/${_check_file}?ref=${_branch}" \
										| head -n4 | grep -I '"sha":' | sed -E 's/.*"([^"]+)".*/\1/')" && {
# 					println::warn "We will need superuser privileges to update the binaries";
					curl -o "$0" "https://github.com/${_user_repo}/raw/${_branch}/${_check_file}" || println::error "Failed to perform the update";
					NO_PULL=true exec "$0" "$@";
				}
			}
		}
	}
}
