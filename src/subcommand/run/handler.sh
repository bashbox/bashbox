# We start with pulling and removing old files from source
## rsync -a --delete "$_src_dir/" "$_target_workdir";
rsync -a "$_src_dir/" "$_target_workdir";
# Now bootstrap the initializer
cat "$_main_src_dir/init.sh" "$_target_workdir/main.sh" > "$_target_workdir/.main.sh.cat";
mv "$_target_workdir/.main.sh.cat" "$_target_workdir/main.sh";
# Change PWD to 
cd "$_target_workdir";
chmod +x "main.sh";
"$PWD/main.sh" "${_run_target_args[@]}";
