#!/bin/bash
# Used to modify arachne/nav.conf.
# Add or remove entries.

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
function print_help() {
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

CONFIG_FILE="$(mythos-dirs 'config' 'arachne')/nav.conf"
if [[ "$1" =~ ^-(h|-help)$ ]]; then 
	print_help 
elif [[ "$1" =~ ^-(r|-remove)$ ]]; then 
	shift 
	_rm_shortcut "$@"
elif [[ "$1" =~ ^-(a|-add)$ ]]; then 
	shift 
	_add_shortcut "$@"
fi
unset CONFIG_FILE
