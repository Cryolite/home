#!/usr/bin/env bash

BAR_INDICATOR=1
MAX_BAR_LENGTH=80
YELLOW_THRESHOLD=50
RED_THRESHOLD=80

[ -f /proc/meminfo ] || exit 1
meminfo="$(cat /proc/meminfo)"
total=$(echo "$meminfo" | grep -F 'MemTotal:' | grep -Eo '[[:digit:]]+')
free=$(echo "$meminfo" | grep -F 'MemFree:' | grep -Eo '[[:digit:]]+')
inactive=$(echo "$meminfo" | grep -F 'Inactive:' | grep -Eo '[[:digit:]]+')
usage=$(($total - ($free + $inactive)))
percentage=$(($usage * 100 / $total))
bar_length=$(($usage * 80 / $total))
total_in_mb=$(($total / 1024))
usage_in_mb=$(($usage / 1024))

if [ $((0 <= $usage_in_mb && $usage_in_mb < 10)) -ne 0 ]; then
  usage_in_mb_oom=1
elif [ $((10 <= $usage_in_mb && $usage_in_mb < 100)) -ne 0 ]; then
  usage_in_mb_oom=2
elif [ $((100 <= $usage_in_mb && $usage_in_mb < 1000)) -ne 0 ]; then
  usage_in_mb_oom=3
elif [ $((1000 <= $usage_in_mb && $usage_in_mb < 10000)) -ne 0 ]; then
  usage_in_mb_oom=4
elif [ $((10000 <= $usage_in_mb && $usage_in_mb < 100000)) -ne 0 ]; then
  usage_in_mb_oom=5
elif [ $((100000 <= $usage_in_mb && $usage_in_mb < 1000000)) -ne 0 ]; then
  usage_in_mb_oom=6
elif [ $((1000000 <= $usage_in_mb && $usage_in_mb < 10000000)) -ne 0 ]; then
  usage_in_mb_oom=7
else
  exit 1
fi

if [ $((0 <= $total_in_mb && $total_in_mb < 10)) -ne 0 ]; then
  total_in_mb_oom=1
elif [ $((10 <= $total_in_mb && $total_in_mb < 100)) -ne 0 ]; then
  total_in_mb_oom=2
elif [ $((100 <= $total_in_mb && $total_in_mb < 1000)) -ne 0 ]; then
  total_in_mb_oom=3
elif [ $((1000 <= $total_in_mb && $total_in_mb < 10000)) -ne 0 ]; then
  total_in_mb_oom=4
elif [ $((10000 <= $total_in_mb && $total_in_mb < 100000)) -ne 0 ]; then
  total_in_mb_oom=5
elif [ $((100000 <= $total_in_mb && $total_in_mb < 1000000)) -ne 0 ]; then
  total_in_mb_oom=6
elif [ $((1000000 <= $total_in_mb && $total_in_mb < 10000000)) -ne 0 ]; then
  total_in_mb_oom=7
else
  exit 1
fi

[ $(($usage_in_mb_oom <= $total_in_mb_oom)) -ne 0 ] || exit 1

padding=''
for i in $(seq 1 $(($total_in_mb_oom - $usage_in_mb_oom))); do
  padding+=' '
done

if [ $BAR_INDICATOR -ne 0 ]; then
  if [ $((0 <= $percentage && $percentage < $YELLOW_THRESHOLD)) -ne 0 ]; then
    echo -en "${padding}${usage_in_mb}MB/${total_in_mb}MB[\005{= kb}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  elif [ $(($YELLOW_THRESHOLD <= $percentage && $percentage < $RED_THRESHOLD)) -ne 0 ]; then
    echo -en "${padding}${usage_in_mb}MB/${total_in_mb}MB[\005{= ky}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  elif [ $(($RED_THRESHOLD <= $percentage)) -ne 0 ]; then
    echo -en "${padding}${usage_in_mb}MB/${total_in_mb}MB[\005{= kr}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  else
    exit 1
  fi
else
  if [ $((0 <= $percentage && $percentage < $YELLOW_THRESHOLD)) -ne 0 ]; then
    echo -e "\005{= bw}${padding}${usage_in_mb}MB/${total_in_mb}MB\005{-}"
  elif [ $(($YELLOW_THRESHOLD <= $percentage && $percentage < $RED_THRESHOLD)) -ne 0 ]; then
    echo -e "\005{= Yk}${padding}${usage_in_mb}MB/${total_in_mb}MB\005{-}"
  elif [ $(($RED_THRESHOLD <= $percentage)) -ne 0 ]; then
    echo -e "\005{= rw}${padding}${usage_in_mb}MB/${total_in_mb}MB\005{-}"
  else
    exit 1
  fi
fi
