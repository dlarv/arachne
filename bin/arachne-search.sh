#!/bin/bash
#shellcheck source=/dev/null

function main()  {
    local excludedDirs excludedTerms parsedExclusions searchTerm
    read -ra excludedDirs <<< "$(mythos-conf arachne 'search.excluded-dirs')"
    read -ra excludedTerms <<< "$(mythos-conf arachne 'search.excluded-terms')"
    parsedExclusions=()

    # Wildcard wrapping 
    if [[ "$1" =~ -(.*w|-no-wildcard-wrap) ]]; then
        searchTerm="$2"
    elif [[ "$1" =~ -(.*W|--wildcard) ]]; then
        searchTerm="*$2*"
    elif [[ "$1" =~ \* ]]; then
        searchTerm="$1"
    else
        searchTerm="*$1*"
    fi
    
    # Parse excluded dirs
    for dir in "${excludedDirs[@]}"; do 

        # Expand ~ to HOME and remove quotes
        dir=${dir//'~'/$HOME}
        dir="${dir//'"'/''}"

        # Ensure empty fields aren't parsed
        if [ ${#dir} -lt 1 ]; then continue; fi

        # Leading '/' is optional in .conf, added back here
        if [ "${dir:0:1}" != '/' ]; then
            dir="/$dir"
        fi

        parsedExclusions+=( '-o' '-ipath' "$dir" '-prune' )
    done

    for term in "${excludedTerms[@]}"; do
        # Remove quotes
        term="${term//'"'/''}"
        
        # Wrap term in wildcards '*'
        if [ "${term:0:1}" != '*' ]; then term="*$term"; fi
        if [ "${term:-1:1}" != '*' ]; then term="$term*"; fi

        parsedExclusions+=( '-o' '-iname' "$term" )
    done

    # Remove leading '-o'
    if [ "${parsedExclusions[0]}" == '-o' ]; then
        parsedExclusions=("${parsedExclusions[@]:1}")
    fi

    find / -type d \( "${parsedExclusions[@]}" \) -o -iname "$searchTerm" -print 2>&1 | grep -v 'Permission denied'
}

if [ $# == 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
    echo "arachne-search [opts] {searchterm}      searches system for {searchterm}, skipping specified directories"
    echo "Directories to skip are listed in arachne.conf"
    echo "Opts:"
    echo "-h|--help                Prints this menu"
    echo "-w|--no-wildcard-wrap    Don't wrap {searchterm} in '*' 
                                   (default if user includes '*' in searchterm)"
    echo "-W|--wildcard            Wrap {searchterm} in '*' (default)"
else
    main "$@"
fi