#!/usr/bin/env bash

set -euo pipefail

. "$HOME/.local/bin/common.sh"

if [[ ! -d $HOME/.screen/sessions ]]; then
  exit 0
fi

while read -r session; do
  if [[ ! -d $HOME/.screen/sessions/$session ]]; then
    continue
  fi
  if [[ -S /run/screen/S-$(whoami)/$session ]]; then
    continue
  fi
  rm -r "$HOME/.screen/sessions/$session"
done <<<$(cd "$HOME/.screen/sessions" && ls -1)
