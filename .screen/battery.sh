#!/usr/bin/env bash

MAX_BAR_LENGTH=80
YELLOW_THRESHOLD=50
RED_THRESHOLD=20

[ -f /sys/class/power_supply/BAT1/energy_now ] || exit 1
[ -f /sys/class/power_supply/BAT1/energy_full ] || exit 1

energy_now=$(cat /sys/class/power_supply/BAT1/energy_now)
energy_full=$(cat /sys/class/power_supply/BAT1/energy_full)
percentage=$(($energy_now * 100 / $energy_full))
bar_length=$(($energy_now * $MAX_BAR_LENGTH / $energy_full))

if [ $(($percentage == 100)) -ne 0 ]; then
  padding=''
elif [ $((10 <= $percentage && $percentage < 100)) -ne 0 ]; then
  padding=' '
elif [ $((0 <= $percentage && $percentage < 10)) -ne 0 ]; then
  padding='  '
else
  exit 1
fi

if [ $(($YELLOW_THRESHOLD <= $percentage && $percentage <= 100)) -ne 0 ]; then
  echo -en "${padding}${percentage}%[\005{= kb}"
  "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
  echo -e "\005{-}]"
elif [ $(($RED_THRESHOLD <= $percentage && $percentage < $YELLOW_THRESHOLD)) -ne 0 ]; then
  echo -en "${padding}${percentage}%[\005{= ky}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -e "\005{-}]"
elif [ $((0 <= $percentage && $percentage <= $RED_THRESHOLD)) -ne 0 ]; then
  echo -en "${padding}${percentage}%[\005{= kr}"
  $(dirname "$0")/num2bar.sh $bar_length $MAX_BAR_LENGTH
  echo -e "\005{-}]"
else
  exit 1
fi
