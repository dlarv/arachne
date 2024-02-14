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

	# Use keys from config as match pattern
	# firefox = "value"
	# Tab that is open - Mozilla FireFox
	while read line; do
		# Get keys
		key="$(grep -Po '^.*(?==|:)' <<< "$line" | sed 's/\s*$//;s/^\s*//')"
		
		# Find key inside NAME
		if grep -iq "$key" <<< "$NAME"; then 
			# Return value contained within "quotes" 
			grep -m 1 -i "^$key" <<< "$line" | grep -Po '(?<=").*(?=")'
			break
		fi

	done < "$config_file"
}

function _get_working_directory() {
	local value
	_get_active_window

	# Close arachne window if it is currently open 
	if [ "$NAME" == 'arachne' ]; then 
		swaymsg 'kill'
		return 2
	elif [ -z "$NAME" ]; then 
		>&2 echo "Window name was empty"
		WORKING_DIR="$HOME"
		return 0
	fi

	value="$(_get_config "$NAME")"

	if [ -z "$value" ]; then
		>&2 echo "No entry in config file matched active window: $NAME"
		WORKING_DIR="$HOME"
		return 0
	elif [ -d "$value" ]; then 
		WORKING_DIR="$value"
		return 0
	fi 

	local lib_dir
	lib_dir="$(mythos-dirs "lib" "arachne")"

	if [ -x "$lib_dir/$value" ]; then
		WORKING_DIR="$(. "$lib_dir/$value" "$NAME" "$PID")"
		echo "$WORKING_DIR"
		return $?
	elif [ -d "$value" ]; then
		WORKING_DIR="$value"
		return 0
	elif [ -d "$HOME/$value" ]; then
		WORKING_DIR="$HOME/$value"
		return 0
	fi 
	>&2 echo "An error occurred"
	WORKING_DIR="$HOME"
}

function _open_term() {
	alacritty --config-file "$HOME/.config/mythos/arachne/arachne.toml" --working-directory "$WORKING_DIR" 
}

function main() {
	local dir
	_get_working_directory || return 2

	# Move arachne-term to active workspace or start one if one DNE.
	swaymsg '[title="Arachne"] move workspace' "$(swaymsg -t get_workspaces | jq '.. | select(.type?) | select(.focused==true) | .name')"  || _open_term ")"

	# Focus on arachne-term
	swaymsg '[title="Arachne"] focus'
}

if [[ "$1" =~ -(h|-help)$ ]]; then
    echo "Opens an alacritty terminal. The working directory is determined by the active window."
	echo "Config file:"
	echo "key = \"path/to/file\" -> CWD is \$HOME/path/to/file"
	echo "key = \"/path/to/file\" -> CWD is /path/to/file"
	echo "key = \"value\" -> Program executes \$MYTHOS_LIB_DIR/arachne/value. CWD is value echoed by this script."
else 
	export NAME PID WORKING_DIR
	main "$@"
	unset NAME PID WORKING_DIR
fi
