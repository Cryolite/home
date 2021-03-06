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
       .config/procps/toprc
       .emacs
       .emacs.d/lisp/term/putty.el
       .emacs.d/lisp/term/screen.putty-256color.el
       .local/bin/common.sh
       .local/bin/reattach
       .screen/ps0-hook.py
       .screen/rm-stale-session-dirs.sh
       .screen/screendir.sh
       .screenrc)
for f in "${files[@]}"; do
    _diff "$f"
done

if uname | grep -Eq '^CYGWIN'; then
    # On Cygwin.
    files=(.minttyrc .git-prompt.sh)
    for f in "${files[@]}"; do
        _diff "$f"
    done
fi
