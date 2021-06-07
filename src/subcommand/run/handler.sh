for _dir in "$_target_dir"; do
	mkdir -p "$_dir";
done

rsync -a --delete "$_src_dir/" "$_target_dir"
cat "$_main_src_dir/init.sh" "$_target_dir/main.sh" > "$_target_dir/.main.sh.cat"
mv "$_target_dir/.main.sh.cat" "$_target_dir/main.sh"
cd "$_target_dir"
chmod +x "main.sh"
"$PWD/main.sh"
