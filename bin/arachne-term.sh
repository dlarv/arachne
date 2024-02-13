#!/bin/bash
#shellcheck source=/dev/null
# Open terminal based on currently focused program
# Gets program name and pid from arachne-launcher
# Parses config file to find appropriate working directory 
# Outputs working directory to arachne-launcher 

function _get_active_window() {
	# This will be swaywm specific
	focusedWindow="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true)')"
	NAME="$(echo "$focusedWindow" | grep "name" | awk '{print $2}' | grep -o '\S*"')"
	PID="$(echo "$focusedWindow" | grep "pid" | grep -o '[0-9]*')"
}

function _get_config() {
	local window_name config_file key
	config_file="$(mythos-dirs conf arachne)/term.conf"
	window_name="${1//\"/}"

	# Find key that best matches [title]
	grep -m 1 -iE "^$window_name" "$config_file" | grep -Eo '".*"' | sed 's/\"//g'
}
function main() {
	export PID NAME
	local value
	_get_active_window
	value="$(_get_config "${NAME,,}")"

	if [ -z "$value" ]; then
		>&2 echo "Could not find program in config file"
		return 1
	elif [ -d "$value" ]; then 
		echo "$value"
		return 0
	fi 

	local lib_dir
	lib_dir="$(mythos-dirs "lib" "arachne")"
	if [ -x "$lib_dir/$value" ]; then
		. "$lib_dir/$value" "$NAME" "$PID"
		unset NAME PID
		return $?
	elif [ -d "$HOME/$value" ]; then
		echo "$value"
		return 0
	fi 
	>&2 echo "Config value '$value' not recognized."
	return 1
}


if [[ "$1" =~ -(h|-help)$ ]]; then
    echo "help"
else 
	main "$@"
fi
