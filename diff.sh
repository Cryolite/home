#!/usr/bin/env bash

function _diff ()
{
    if [[ ! -e $1 ]]; then
        echo "\`$1' does not exist. There may a stale entry in \`diff.sh'." >&2
        return
    fi

    if [[ -e $1 && ! -e ~/$1 ]]; then
        echo "\`$1' exists, but \`~/$1' does not." >&2
        return
    fi

    if ! diff -q "$1" ~/"$1" &>/dev/null; then
        echo "\`$1' and \`~/$1' differs." >&2
        return
    fi
}

files=(.bashrc
       .emacs
       .emacs.d/lisp/cmake-mode.el
       .emacs.d/lisp/yaml-mode.el
       .local/bin/common.sh
       .local/bin/reattach
       .screen/hardware-status.py
       .screen/ps0-hook.py
       .screen/rm-stale-session-dirs.sh
       .screen/screendir.sh
       .screenrc
       .toprc)
for f in "${files[@]}"; do
    _diff "$f"
done

if uname | grep -Eq '^CYGWIN'; then
    # On Cygwin.
    files=(.minttyrc)
    for f in "${files[@]}"; do
        _diff "$f"
    done
fi
