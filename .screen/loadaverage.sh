#!/usr/bin/env bash

MAX_LOAD_AVERAGE=4
MAX_BAR_LENGTH=80
load_average=$(uptime | grep -Eo 'load average: [[:digit:]]\.[[:digit:]][[:digit:]]' | grep -Eo '[[:digit:]]\.[[:digit:]][[:digit:]]')
bar_length=$(echo "scale=0; $load_average * 100" | bc | grep -Eo '^[[:digit:]]+')
bar_length=$(($bar_length * $MAX_BAR_LENGTH / $MAX_LOAD_AVERAGE / 100))
if [[ $((0 <= $bar_length && $bar_length < 40)) != 0 ]]; then
  echo -en "${load_average}[\005{= kb}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((40 <= $bar_length && $bar_length < $MAX_BAR_LENGTH)) != 0 ]]; then
  echo -en "${load_average}[\005{= ky}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $(($MAX_BAR_LENGTH <= $bar_length)) != 0 ]]; then
  echo -en "${load_average}[\005{= kr}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
else
  exit 1
fi
