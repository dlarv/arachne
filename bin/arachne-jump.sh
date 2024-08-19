#!/bin/bash
function _match_arg() {
	grep -m 1 -E "^$1" "$CONFIG_FILE" | sed -E "s/.*(=|:)\s*//;s/\$HOME/~/;s|~|$HOME|;s/\"//g"
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

function _arachne_jump() {
	local target
	target="$(_match_arg "$1")"
	if [ -z "$target" ]; then
		if [ -d "$1" ]; then 
			pushd "$1" ||	return 1
		elif [ -f "$1" ]; then 
			pushd "$(dirname "$1")" ||	return 1
		else 
			echo "Cannot jump to $1, directory not found."
			return 1
		fi
		return 0
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

function _print_help() {
	echo "arachne-mod opt [shortcut] [path]"
	echo "-a | --add"
	echo "Appends new shortcut to bottom of arachne config file."
	echo "If either shortcut or path are left empty, user will be prompted for input."
	echo ""
	echo " -r | --remove"
	echo "Removes shortcut from config file."
	echo "If the shortcut is omitted, user will be prompted for input."
	echo "Internally, this command uses sed -i '/\$shortcut/d' to edit config file. This change cannot be undone."
}

function main() {
	if [[ "$1" =~ ^-(b|-back) ]]; then
		popd || return 1
	elif [[ "$1" =~ ^-(h|-help)$ ]]; then 
		_print_help
	else 
		_arachne_jump "$@"
	fi
}

CONFIG_FILE="$(mythos-dirs 'config' 'arachne')/nav.conf"

# For commands like cd to work, file needs to be run directly. 
# Therefore, arachne's commands are defined inside arachne_vars.sh as aliases. 

# Prevents "dir/*" from returning a literal "*" if "dir" is empty
# https://mywiki.wooledge.org/ParsingLs
shopt -s nullglob
main "$@"
unset CONFIG_FILE
