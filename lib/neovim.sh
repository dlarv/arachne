#!/bin/bash

child="$2"
parent=''

while [ -n "$child" ]; do 
	parent="$child"
	child="$(pgrep -P "$parent")"
done

readlink -f "/proc/$parent/cwd"

