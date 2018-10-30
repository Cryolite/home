#!/usr/bin/env bash

set -euo pipefail

. "$HOME/.local/bin/common.sh"

{ screen -ls || true; } \
  | grep -E '^(No Sockets found|1 Socket|[1-9][[:digit:]]* Sockets) in ' \
  | sed -e 's/^\(No Sockets found\|1 Socket\|[[:digit:]]* Sockets\) in \(.*\)\./\2/'
