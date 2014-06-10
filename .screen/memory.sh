#!/usr/bin/env bash

[ -f /proc/meminfo ] || exit 1
meminfo="$(cat /proc/meminfo)"
total=$(echo "$meminfo" | grep -F 'MemTotal:' | grep -Eo '[[:digit:]]+')
free=$(echo "$meminfo" | grep -F 'MemFree:' | grep -Eo '[[:digit:]]+')
inactive=$(echo "$meminfo" | grep -F 'Inactive:' | grep -Eo '[[:digit:]]+')
usage=$(($total - ($free + $inactive)))
MAX_BAR_LENGTH=80
bar_length=$(($usage * 80 / $total))
total=$(($total / 1024))
usage=$(($usage / 1024))
if [[ $((0 <= $bar_length && $bar_length < 40)) != 0 ]]; then
  echo -en "${usage}MB/${total}MB[\005{= kb}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((40 <= $bar_length && $bar_length < 64)) != 0 ]]; then
  echo -en "${usage}MB/${total}MB[\005{= ky}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((64 <= $bar_length)) != 0 ]]; then
  echo -en "${usage}MB/${total}MB[\005{= kr}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
else
  exit 1
fi
