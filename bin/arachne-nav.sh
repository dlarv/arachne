#!/bin/bash
#shellcheck source=/dev/null

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
function _add_shortcut() {
	local shortcut target

	# Get shortcut name
	shortcut="$1"
	if [ -z "$1" ]; then
		echo -n "Enter shortcut name: "
		read shortcut 
		if [ -z "$shortcut" ]; then 
			echo "User cancelled command."
			return 1
		fi
	fi

	# Get path targeted by shortcut 
	if [ -z "$2" ]; then 
		read -ep "Enter target path (default="."): " target 
	else
		target="$2"
	fi

	# Make sure target is a valid path 
	if [ -z "$target" ]; then 
		target="$PWD"
	elif [ ! -d "$target" ]; then
		if [ -e "$PWD/$target" ]; then
			target="$PWD/$target"
		else
			echo "Could not add shortcut. \"$target\" is not a directory"
			return 1
		fi 
	fi
	# Change $HOME to '~'
	# This allows config file to be portable
	target="$(sed "s|$HOME|~|" <<< "$target")"
	echo "$shortcut = \"$target\"" >> "$CONFIG_FILE"
}
function _rm_shortcut() {
	local shortcut 

	# Get shortcut name
	shortcut="$1"
	if [ -z "$1" ]; then
		echo -n "Enter shortcut to delete: "
		read shortcut 
		if [ -z "$shortcut" ]; then 
			echo "User cancelled command."
			return 1
		fi
	fi
	sed -i "/$shortcut/d" "$CONFIG_FILE"
}

function _arachne_jump() {
    if [[ "$1" =~ ^-(b|-back) ]]; then
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
function _print_shortcuts() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Arachne config file could not be found. Exiting."
        return 1
	fi
    if [ -n "$1" ]; then
        echo "Provides a shorthand to {$1} into the following dirs:"
    else
        echo "Arachne shorthand:"
    fi

	cat "$CONFIG_FILE"
}
function _help() {
	case "$1" in
		'jump' | 'look' | 'back') _print_shortcuts "$1" ;;
		'add') 
			echo "arachne-nav -a [shortcut] [path]"
			echo "Appends new shortcut to bottom of arachne config file."
			echo "If either shortcut or path are left empty, user will be prompted for input."
			;;
		'remove')
			echo "arachne-nav -r [shortcut]"
			echo "Removes shortcut from config file."
			echo "If the shortcut is omitted, user will be prompted for input."
			echo "Internally, this command uses sed -i '/\$shortcut/d' to edit config file. This change cannot be undone."
			;;
		*)
			echo "arachne-nav -j|-l|-b [shortcut] [subdirs]"
			echo "arachne-nav -a [shortcut] [path]"
			echo "arachne-nav -r [shortcut]"
			echo "NOTE: For commands like cd/pushd to work, the script needs to be run directly. Therefore, arachne's should be defined as aliases. e.g. alias ajump=\"./\$MYTHOS_BIN_DIR/arachne-nav -j\""
			echo "Opts:"
			echo -e "-h | --help\t\tPrint this menu."
			echo -e "-p | --print\t\tPrint list of shortcuts."
			echo -e "-a | --add\t\tAdd new shortcut."
			echo -e "-r | --rm\t\tRemove shortcut."
			echo -e "-j | --jump\t\tJump to shortcut. Wrapper for pushd."
			echo -e "-b | --back\t\tWrapper for popd."
			echo -e "-l | --look\t\tLook inside shortcut. Wrapper for ls."
	esac
}

function main() {
	local print_help nav_mode edit_config_mode args
	args=()
	for arg in $(mythos-args "$@"); do 
		if [[ "$arg" =~ ^-(p|-print)$ ]]; then
			_print_shortcuts
			return 0
		elif [[ "$arg" =~ ^-(h|-help)$ ]]; then
			print_help=1
		elif [[ ! "$arg" =~ ^-.* ]]; then  
			args+=("$arg")
		elif [[ "$arg" =~ ^-(a|-add)$ ]]; then
			edit_config_mode="add"
		elif [[ "$arg" =~ ^-(r|(-r(m|emove)))$ ]]; then
			edit_config_mode="rm"
		elif [[ "$arg" =~ ^-(l|-look)$ ]]; then
			nav_mode="look"
		elif [[ "$arg" =~ ^-(j|-jump)$ ]]; then
			nav_mode="jump"
		elif [[ "$arg" =~ ^-(b|-back)$ ]]; then
			nav_mode="back"
		else 
			>&2 echo "Unknown opt: $arg"
			return 1
		fi
	done

	local mode
	# edit_mode > nav_mode
	mode="${edit_config_mode:-$nav_mode}"
	if [ -n "$print_help" ]; then
		_help "$mode"
	# edit_mode and -b can have empty args, nav_mode cannot
	elif [ "$edit_config_mode" == "add" ]; then
		_add_shortcut "${args[@]}"
	elif [ "$edit_config_mode" == "rm" ]; then
		_rm_shortcut "${args[@]}"
	elif [ "$nav_mode" == "back" ]; then
		_arachne_jump '-b' "${args[@]}"
	elif [ -z "${args[*]}" ]; then 
		_help "$mode"
	elif [ "$nav_mode" == "jump" ]; then
		_arachne_jump "${args[@]}"
	elif [ "$nav_mode" == "look" ]; then
		_arachne_look "${args[@]}"
	else 
		>&2 echo "Please provide a mode (-l|-j|-a|-r)."
		return 1
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
