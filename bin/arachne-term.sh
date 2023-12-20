#!/bin/bash
#shellcheck source=/dev/null
# Open terminal based on currently focused program
function _get_config() 
{
    local confDir
    confDir="$(mythos-dir conf arachne)/arachne.conf"
    local file="$(cat "$confDir")"
    file="${file/*\[terminal\]/}"
    while read -ra line; do 
        
        if [ -z "${line[*]}" ]; then continue; fi
        line="$(echo "${line[*]}" | sed -E "s/(=|:)//g")"

        if [[ "$line" =~ ^\[.*\]$ ]]; then
            break 
        fi
        # Remove = or : to make parsing easier
        if grep -qi "$(awk '{ print $1 }' <<< "$line")" <<< "$1"; then
            awk '{ print $2 }' <<< "$line"
            break 
        fi

    done <<< "$file"
}
function main()
{
    local programDir
    programDir="$(_get_config "$@")"
    programDir="${programDir/'~'/$HOME}"
    : ${programDir:=$HOME}
    # "" must be stripped from path
    alacritty -v --working-directory "${programDir//\"/}" --config-file "$HOME/.config/mythos/arachne/arachne.yml" 
}


if [[ "$1" =~ -(h|-help)$ ]]; then
    echo "help"
elif [ -n "$1" ]; then
    main "$@"
fi
