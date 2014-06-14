#!/usr/bin/env bash

set -e

list="$(screen -ls || true)"

for session_dir in "$HOME/.screen/sessions/"*; do
    session=${session_dir##*/}
    if echo "$list" | grep -Fq "$session"; then
        :
    else
        rm -r "$session_dir"
    fi
done
