#!/bin/bash
name="$(echo "$1" | sed 's/ — libreoffice writer$//')"
pid="$2"

for file in "/proc/$pid/fd/"*; do
	dir="$(readlink "$file" | grep -i "$name")"

	if [ -f "$dir" ]; then
		dirname "$dir"
		break
	fi

done 
unset name pid file dir
