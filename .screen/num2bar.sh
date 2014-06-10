#!/usr/bin/env bash

[[ $# == 1 || $# == 2 ]] || exit 1

if [[ $# == 2 ]]; then
  if [[ $(($1 <= $2)) != 0 ]]; then
    val=$1
  else
    val=$2
  fi
fi

num_fullblocks=$(($val / 8))
for i in $(seq 1 $num_fullblocks); do
  echo -en '\xE2\x96\x88'
done

case $(($val % 8)) in
  0) ;;
  1) echo -en '\xE2\x96\x8F';;
  2) echo -en '\xE2\x96\x8E';;
  3) echo -en '\xE2\x96\x8D';;
  4) echo -en '\xE2\x96\x8C';;
  5) echo -en '\xE2\x96\x8B';;
  6) echo -en '\xE2\x96\x8A';;
  7) echo -en '\xE2\x96\x89';;
  *) exit 1;;
esac

if [[ $# == 2 ]]; then
  num_padding=$((($2 - $val) / 8))
  for i in $(seq 1 $num_padding); do
    echo -n ' '
  done
fi
