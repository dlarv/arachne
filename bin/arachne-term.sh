#!/bin/bash
#shellcheck source=/dev/null
# Open terminal based on currently focused program
# Gets program name and pid from arachne-launcher
# Parses config file to find appropriate working directory 
# Outputs working directory to arachne-launcher 

function _get_active_window() {
	local focused_window
	# This is swaywm specific
	focused_window="$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true)')"

	# Get name of window and remove : ""
	NAME="$(echo "$focused_window" | grep "name" |  grep -o ': ".*"' | sed 's/^: //;s/\"//g')"
	# Make name lowercase
	NAME="${NAME,,}"
	# Get PID
	PID="$(echo "$focused_window" | grep "pid" | grep -o '[0-9]*')"
}

function _get_config() {
	local window_name config_file key
	config_file="$(mythos-dirs conf arachne)/term.conf"
	window_name="${1//\"/}"

	# Find key that best matches [title]
	grep -m 1 -iE "^$window_name" "$config_file" | grep -Eo '".*"'
}
function _get_working_directory() {
	local value
	_get_active_window

	# Close arachne window if it is currently open 
	if [ "$NAME" == 'arachne' ]; then 
		swaymsg 'kill'
		return 2
	elif [ -z "$NAME" ]; then 
		>&2 echo "No entry in config file matched active window: $NAME"
		return 1
	fi

	value="$(_get_config "$NAME")"

	if [ -z "$value" ]; then
		>&2 echo "No entry in config file matched active window: $NAME"
		return 1
	elif [ -d "$value" ]; then 
		WORKING_DIR="$value"
		return 0
	fi 

	local lib_dir
	lib_dir="$(mythos-dirs "lib" "arachne")"
	if [ -x "$lib_dir/$value" ]; then
		WORKING_DIR="$(. "$lib_dir/$value" "$NAME" "$PID")"
		return $?
	elif [ -d "$HOME/$value" ]; then
		WORKING_DIR="$value"
		return 0
	fi 
	>&2 echo "No entry in config file matched active window: $NAME"
	return 1
}

function _open_term() {
	alacritty --config-file "$HOME/.config/mythos/arachne/arachne.yml" --working-directory "$WORKING_DIR" 
}

function main() {
	local dir
	_get_working_directory || return 1
	# Move arachne-term to active workspace or start one if one DNE.
	swaymsg '[title="Arachne"] move workspace' "$(swaymsg -t get_workspaces | jq '.. | select(.type?) | select(.focused==true) | .name')"  || _open_term")"
	# Focus on arachne-term
	swaymsg '[title="Arachne"] focus'
}

if [[ "$1" =~ -(h|-help)$ ]]; then
    echo "help"
else 
	export NAME PID WORKING_DIR
	main "$@"
	unset NAME PID WORKING_DIR
fi
