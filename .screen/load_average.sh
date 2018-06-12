#!/usr/bin/env bash

BAR_INDICATOR=1
MAX_BAR_LENGTH=80
YELLOW_THRESHOLD=50
RED_THRESHOLD=100

load_average=$(uptime | grep -Eo 'load average: [[:digit:]]+\.[[:digit:]][[:digit:]]' | grep -Eo '[[:digit:]]+\.[[:digit:]][[:digit:]]')
load_average_centuple=$(echo "scale=0; $load_average * 100" | bc | grep -Eo '^[[:digit:]]+')
max_load_average=$(nproc)
percentage=$(($load_average_centuple / $max_load_average))

if [ $((0 <= $load_average_centuple && $load_average_centuple < 1000)) -ne 0 ]; then
  load_average_oom=1
elif [ $((1000 <= $load_average_centuple && $load_average_centuple < 10000)) -ne 0 ]; then
  load_average_oom=2
elif [ $((10000 <= $load_average_centuple && $load_average_centuple < 100000)) -ne 0 ]; then
  load_average_oom=3
else
  exit 1
fi

if [ $((0 <= $max_load_average && $max_load_average < 10)) -ne 0 ]; then
  max_load_average_oom=1
elif [ $((10 <= $max_load_average && $max_load_average < 100)) -ne 0 ]; then
  max_load_average_oom=2
elif [ $((100 <= $max_load_average && $max_load_average < 1000)) -ne 0 ]; then
  max_load_average_oom=3
else
  exit 1
fi

[ $(($load_average_oom <= $max_load_average_oom)) -ne 0 ] || exit 1

padding=''
for i in $(seq 1 $(($max_load_average_oom - $load_average_oom))); do
  padding+=' '
done

if [ $BAR_INDICATOR -ne 0 ]; then
  bar_length=$((($load_average_centuple * $MAX_BAR_LENGTH) / ($max_load_average * 100)))
  if [ $((0 <= $percentage && $percentage < $YELLOW_THRESHOLD)) -ne 0 ]; then
    echo -en "$padding$load_average/$max_load_average.00[\005{= kb}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  elif [ $(($YELLOW_THRESHOLD <= $percentage && $percentage < $RED_THRESHOLD)) -ne 0 ]; then
    echo -en "$padding$load_average/$max_load_average.00[\005{= ky}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  elif [ $(($RED_THRESHOLD <= $percentage)) -ne 0 ]; then
    echo -en "$padding$load_average/$max_load_average.00[\005{= kr}"
    "$(dirname "$0")/num2bar.sh" $bar_length $MAX_BAR_LENGTH
    echo -e "\005{-}]"
  else
    exit 1
  fi
else
  if [ $((0 <= $percentage && $percentage < $YELLOW_THRESHOLD)) -ne 0 ]; then
    echo -e "\005{= bw}$padding$load_average/$max_load_average.00\005{-}"
  elif [ $(($YELLOW_THRESHOLD <= $percentage && $percentage < $RED_THRESHOLD)) -ne 0 ]; then
    echo -e "\005{= Yk}$padding$load_average/$max_load_average.00\005{-}"
  elif [ $(($RED_THRESHOLD <= $percentage)) -ne 0 ]; then
    echo -e "\005{= rw}$padding$load_average/$max_load_average.00\005{-}"
  else
    exit 1
  fi
fi
