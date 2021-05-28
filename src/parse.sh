#!/usr/bin/bash
_out=out.shc
echo > out.shc
while read -r line; do
	if grep -E '.*;$' <<<"$line" 1>/dev/null; then
		echo -n "$line" >> "$_out"
	else
		echo "$line" >> "$_out"
	fi
done < $1
