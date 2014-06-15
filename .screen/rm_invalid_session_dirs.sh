#!/usr/bin/env bash

set -e

list="$(screen -ls || true)"

for session_dir in "$HOME/.screen/sessions/"*; do
    if [ "$session_dir" = "$HOME/.screen/sessions/*" ]; then
        break
    fi
    session=${session_dir##*/}
    if echo "$session" | grep -Eq "\.$(uname -n)\$"; then
        if echo "$list" | grep -Fq "$session"; then
            :
        else
            rm -r "$session_dir"
        fi
    fi
done
