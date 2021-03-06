#!/usr/bin/env bash

set -euo pipefail

. "$HOME/.local/bin/common.sh"

# `screen -ls` on screen 4.0 exits with a non-zero status code.
# `screen -ls` on screen 4.06.02 ends with `\r\n`, not `\n`.
{ screen -ls || true; } \
  | grep -E '^(No Sockets found|1 Socket|[1-9][[:digit:]]* Sockets) in ' \
  | sed -e 's/^\(No Sockets found\|1 Socket\|[[:digit:]]* Sockets\) in \(.*\)\.[[:space:]]*$/\2/'
