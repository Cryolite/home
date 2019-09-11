#!/usr/bin/env bash

set -euo pipefail

. "$HOME/.local/bin/common.sh"

if [[ ! -d $HOME/.screen/sessions ]]; then
  exit 0
fi

while IFS= read -r -d '' session_dir; do
  session="$(basename "$session_dir")"
  if [[ -p $("$HOME/.screen/screendir.sh")/$session ]]; then
    # On CentOS 6.9, the entity in the socket directory corresponding to an
    # existing session is a fifo.
    continue
  fi
  if [[ -S $("$HOME/.screen/screendir.sh")/$session ]]; then
    # On Debian 9 (Stretch) and CentOS 7, the entity in the socket directory
    # corresponding to an existing session is a socket.
    continue
  fi
  rm -r "$HOME/.screen/sessions/$session"
done < <(find "$HOME/.screen/sessions" -mindepth 1 -maxdepth 1 -type d -print0)
