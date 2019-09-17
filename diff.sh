#!/usr/bin/env bash

files=(.bashrc
       .emacs
       .emacs.d/lisp/cmake-mode.el
       .emacs.d/lisp/yaml-mode.el
       .local/bin/common.sh
       .local/bin/reattach
       .minttyrc
       .screen/hardware-status.py
       .screen/ps0-hook.py
       .screen/rm-stale-session-dirs.sh
       .screen/screendir.sh
       .screenrc
       .toprc)
for f in "${files[@]}"; do
    if [[ ! -e $f ]]; then
        echo "\`$f' does not exist. There may a stale entry in \`diff.sh'." >&2
        continue
    fi

    if [[ -e $f && ! -e ~/$f ]]; then
        echo "\`$f' exists, but \`~/$f' does not." >&2
        continue
    fi

    if ! diff -q "$f" ~/"$f" &>/dev/null; then
        echo "\`$f' and \`~/$f' differs." >&2
        continue
    fi
done
