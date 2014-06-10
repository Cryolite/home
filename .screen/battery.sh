#!/usr/bin/env bash

[[ -f '/sys/class/power_supply/BAT1/energy_now' && -f '/sys/class/power_supply/BAT1/energy_full' ]] || exit 1
energy_now=$(cat '/sys/class/power_supply/BAT1/energy_now')
energy_full=$(cat '/sys/class/power_supply/BAT1/energy_full')
percentage=$(($energy_now * 100 / $energy_full))
MAX_BAR_LENGTH=80
bar_length=$(($energy_now * $MAX_BAR_LENGTH / $energy_full))
if [[ $(($percentage == 100)) != 0 ]]; then
  echo -en "${percentage}%[\005{= kb}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((50 < $percentage && $percentage <= 99)) != 0 ]]; then
  echo -en " ${percentage}%[\005{= kb}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((20 < $percentage && $percentage <= 50)) != 0 ]]; then
  echo -en " ${percentage}%[\005{= ky}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((10 <= $percentage && $percentage <= 20)) != 0 ]]; then
  echo -en " ${percentage}%[\005{= kr}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
elif [[ $((0 <= $percentage && $percentage <= 9)) != 0 ]]; then
  echo -en "  ${percentage}%[\005{= kr}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -en "\005{-}]"
else
  exit 1
fi
