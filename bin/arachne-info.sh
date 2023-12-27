#!/bin/bash
#shellcheck source=/dev/null

# du -h
function main() {
    # c=total, s=summarize, h=human-readable
    if [ -z "$1" ]; then        
        du -csh ./*
    else
        du -csh "$@"
    fi
}

if [[ "$1" =~ ^-(h|-help)$ ]]; then
    echo "Wrapper for du"
else
    main "$@"
fi
