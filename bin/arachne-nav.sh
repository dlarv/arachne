#!/bin/bash
#shellcheck source=/dev/null

function _match_arg() {
	grep -m 1 -E "^$1" "$CONFIG_FILE" | sed -E "s/.*(=|:)\s*//;s/\$HOME/~/;s|~|$HOME|"
}

# $1 is the parent path
# $2 is the fragment to resolve 
# Return codes:
# 1: Could not resolve fragment
# 2: Fragment is a file (error to jump command)
# 3: Fragment is a directory 
function _resolve_path() {
	local path
	path="$1/$2"
	if [ -f "$path" ]; then
		echo "$2"
		return 2
	elif [ -d "$path" ]; then
		echo "$2"
		return 3
	fi

	# Try to match snippet to item in parent
	for item in "$1/"*; do
		path="$(basename "$item")"
		if [[ ! "$path" =~ ^"$2" ]]; then
			continue
		fi

		if [ -f "$1/$path" ]; then
			echo "$path"
			return 2
		elif [ -d "$1/$path" ]; then 
			echo "$path"
			return 3
		fi
	done
	return 1
}
function _help() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Arachne config file could not be found. Exiting."
        return
	fi

    if [ -n "$1" ]; then
        echo "Provides a shorthand to {$1} into the following dirs:"
    else
        echo "Arachne shorthand:"
    fi

	cat "$CONFIG_FILE"
}

function _arachne_jump() {
    if [[ "$1" =~ ^()$|(^(-)*h(elp)*$) ]]; then
        _help 'cd'
		return 0
    elif [[ "$1" =~ ^-(b|-back) ]]; then
        popd || return 1
		return 0
	fi

	local target
	target="$(_match_arg "$1")"
	if [ -z "$target" ]; then
		echo "Cannot jump to $1, directory not found."
	fi
	# resolve remaining args 
	shift
	while [ $# -gt 0 ]; do
		# If $1 is a path, append it to target 
		# Elif $1 is a 
		path_snippet="$(_resolve_path "$target" "$1")"
		if [ $? == 1 ]; then
			echo "Cannot match $1 to any contents of $target"
			return 1
		fi
		target+="/$path_snippet"
		shift
	done
	pushd "$target" || return 1
}
function _arachne_look() {
	if [ $# == 0 ]; then 
		_help 'ls'
		return 0
	fi
	local target path_snippet

	# Get main directory snippet 
	target="$(_match_arg "$1")"
	if [ -z "$target" ]; then
		echo "Cannot look in $1, directory not found."
		return 1
	fi

	# resolve remaining args 
	shift
	while [ $# -gt 0 ]; do
		# If $1 is a path, append it to target 
		# Elif $1 is a 
		path_snippet="$(_resolve_path "$target" "$1")"
		if [ $? == 1 ]; then
			echo "Cannot match $1 to any contents of $target"
			return 1
		fi
		target+="/$path_snippet"
		shift
	done
	echo "Looking at: $target"
	ls "$target"
}
CONFIG_FILE="$MYTHOS_LOCAL_CONFIG_DIR/arachne/nav.conf"

# For commands like cd to work, file needs to be run directly. 
# Therefore, arachne's commands are defined inside arachne_vars.sh as aliases. 
# Prevents "dir/*" from returning a literal "*" if "dir" is empty
# https://mywiki.wooledge.org/ParsingLs
shopt -s nullglob
if [ -z "$1" ] || [[ "$1" =~ ^-(h|-help) ]] || [[ "$2" =~ ^-(h|-help) ]]; then
    _help
elif [ "$1" == "jump" ]; then
    _arachne_jump "${@:2}"
elif [ "$1" == "look" ]; then
    _arachne_look "${@:2}"
fi
unset CONFIG_FILE
