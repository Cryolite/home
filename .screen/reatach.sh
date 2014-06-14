#!/usr/bin/env bash

set -e
if false; then
    PS4='+$0:$LINENO: '
    set -x
fi

[ $# -eq 0 -o $# -eq 1 ] || {
    echo 'reatach:error: usage: reatach [pid[.tty.host]]' >&2
    exit 1
}

"$HOME/.screen/rm_invalid_session_dirs.sh"

list="$(screen -ls || true)"

exec_screen ()
{
    if [ -z "$SSH_AUTH_SOCK" -a -z "$SSH_CLIENT" -a -z "$SSH_CONNECTION" -a -z "$SSH_TTY" ]; then
        cat > "$session_dir/fix-ssh-agent.sh" <<EOF
\\unset SSH_AUTH_SOCK
\\unset SSH_CLIENT
\\unset SSH_CONNECTION
\\unset SSH_TTY
\\rm "$session_dir/fix-ssh-agent.sh"
EOF
        chmod 700 "$session_dir/fix-ssh-agent.sh"
        exec screen -r $1
    fi
    if [ -n "$SSH_AUTH_SOCK" -a -z "$SSH_CLIENT" -a -z "$SSH_CONNECTION" -a -z "$SSH_TTY" ]; then
	cat > "$session_dir/fix-ssh-agent.sh" <<EOF
\\export SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
\\unset SSH_CLIENT
\\unset SSH_CONNECTION
\\unset SSH_TTY
\\rm "$session_dir/fix-ssh-agent.sh"
EOF
	chmod 700 "$session_dir/fix-ssh-agent.sh"
	exec screen -r $1
    fi
    if [ -n "$SSH_AUTH_SOCK" -a -n "$SSH_CLIENT" -a -n "$SSH_CONNECTION" -a -n "$SSH_TTY" ]; then
	cat > "$session_dir/fix-ssh-agent.sh" <<EOF
\\export SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
\\export SSH_CLIENT="$SSH_CLIENT"
\\export SSH_CONNECTION="$SSH_CONNECTION"
\\export SSH_TTY="$SSH_TTY"
\\rm "$session_dir/fix-ssh-agent.sh"
EOF
	chmod 700 "$session_dir/fix-ssh-agent.sh"
	exec screen -r $1
    fi
}

case $# in
0)
    num_detached=$(echo "$list" | grep -F 'Detached' | wc -l)
    [ $num_detached -eq 0 ] && {
        screen -ls | sed -e 's/[[:digit:]]\{1,\} Sockets\{0,1\} in.*$/There is no screen to be resumed./' >&2
        exit 1
    }
    [ $num_detached -ne 1 ] && {
        screen -ls \
            | sed -e 's/There are screens on:/There are several suitable screens on:/' \
            | sed -e 's/[[:digit:]]\{1,\} Sockets\{0,1\} in.*$/Type "reatach pid[.tty.host]" to resume one of them./' >&2
        exit 1
    }
    session="$(echo "$list" | grep -F 'Detached' | grep -Eo '[[:digit:]]+\.[^\.]+\.[^[:space:]]+')"
    session_dir="$HOME/.screen/sessions/$session"
    mkdir -m 700 -p "$session_dir"
    exec_screen
    echo 'reatach.sh:error: a logic error' >&2
    exit 1
    ;;
1)
    { echo "$list" | grep -Eo '[[:digit:]]+\.[^\.]+\.[^[:space:]]' | grep -Fq "$1"; } || {
        screen -ls \
            | sed -e "s/[[:digit:]]\\{1,\\} Sockets\\{0,1\\} in.*\$/There is no screen to be resumed matching $1./" \
            | sed -e "s/No Sockets found in .*\$/There is no screen to be resumed matching $1./" >&2
        exit 1
    }
    if [ $(echo "$list" | grep -Eo '[[:digit:]]+\.[^\.]+\.[^[:space:]]' | grep -F "$1" | wc -l) -ne 1 ]; then
        screen -ls \
            | sed -e 's/There are screens on:/There are several suitable screens on:/' \
            | sed -e 's/[[:digit:]]\{1,\} Sockets\{0,1\} in.*$/Type "screen [-d] -r [pid].tty.host" to resume one of them./' >&2
        exit 1
    fi
    { echo "$list" | grep -F 'Detached' | grep -Eo '[[:digit:]]+\.[^\.]+\.[^[:space:]]' | grep -Fq "$1"; } || {
        screen -ls | sed -e "s/[[:digit:]]\\{1,\\} Sockets\\{0,1\\} in.*\$/There is no screen to be resumed matching $1./" >&2
        exit 1
    }
    session="$(echo "$list" | grep -Eo '[[:digit:]]+\.[^\.]+\.[^[:space:]]' | grep -F "$1")"
    session_dir="$HOME/.screen/sessions/$session"
    mkdir -m 700 -p "$session_dir"
    exec_screen "$session"
    echo 'reatach.sh:error: a logic error' >&2
    exit 1
    ;;
*)
    echo 'reatach.sh:error: a logic error' >&2
    exit 1
    ;;
esac

echo 'reatach.sh:error: a logic error' >&2
exit 1
