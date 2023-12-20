#!/bin/bash
#shellcheck source=/dev/null

function _match_arg() {
	grep -m 1 -E "^$1" "$CONFIG_FILE" | sed -E "s/.*(=|:)\s*//;s/\$HOME/~/;s|~|$HOME|"
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
    # Match empty, -h, --help, etc
    # Print help menu
    if [[ "$1" =~ ^()$|(^(-)*h(elp)*$) ]]; then
        _help 'cd'

    elif [[ "$1" =~ ^-(b|-back) ]]; then
        popd || return

    else
        target="$(_match_arg "$1")"
        if [ -z "$target" ]; then
            echo "Cannot jump to $1, directory not found."

        else 
            pushd "$target" || return
        fi
    fi
}
function _arachne_look() {
    # Match empty, -h, --help, etc
    # Print help menu
    if [[ "$1" =~ ^()$|(^(-)*h(elp)*$) ]]; then
        _help 'ls'
    else
        target="$(_match_arg "$1")"
        if [ -z "$target" ]; then
            echo "Cannot look in $1, directory not found."
        else 
            ls "$target"
        fi
    fi
}

# For commands like cd to work, file needs to be run directly. 
# Therefore, arachne's commands are defined inside arachne_vars.sh as aliases. 

CONFIG_FILE="$MYTHOS_LOCAL_CONFIG_DIR/arachne/nav.conf"
if [ -z "$1" ] || [[ "$1" =~ ^-(h|-help) ]]; then
    _help
elif [ "$1" == "jump" ]; then
    _arachne_jump "$2"
elif [ "$1" == "look" ]; then
    _arachne_look "$2"
fi
unset CONFIG_FILE
