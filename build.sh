function bashbox_before_build() {
	:;
}

function bashbox_after_build() {
	rsync -a "$_target_workfile" "$_arg_path/bashbox";
	chmod +x "$_arg_path/bashbox";
}