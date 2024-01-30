#!/bin/bash
# Wrapper for zip
# Because I can never remember the right args 

function main() {
	local out target 

	while [ $# -gt 0 ]; do
		if [ "$1" == "-o" ]; then
			out="$2"
			shift
			shift 
		elif [ -n "$target" ]; then
			>&2 echo "ARACHNE (Error): Too many args provided."
			return 1
		else
			target="$1"
			shift
		fi
	done

	zip -r "${out:-$(basename "$target")}.zip" "$target" "${opts[@]}"
}

if [ -z "$1" ] || [[ "$1" =~ ^-(h|-help)$ ]]; then
	echo "Wrapper for zip"
	echo "zip -r archive.zip archive/*"
	echo "azip archive" 
	echo "azip [-o output-name] archive" 
elif [[ "$1" =~ ^-(e|echo)$ ]]; then
	echo "zip -r ${2:-archive}.zip ${2:-archive}"'/*'
else 
	main "$@"
fi
