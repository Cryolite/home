# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

ulimit -c unlimited

export PATH="${HOME}/local/bin${PATH:+:$PATH}"

#if [ -f /etc/debian_version ] && grep -Fq 'squeeze/sid' /etc/debian_version; then
#    export LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LIBRARY_PATH:+:$LIBRARY_PATH}"
#    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
#fi

export BOOST_ROOT="${HOME}/local/boost/latest"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export EDITOR='emacs -nw'

if [ -t 0 ]; then
  stty stop undef
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color|screen*) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias cd='pushd'
alias p='popd'
alias ll='ls -l'
alias la='ls -A'
alias lla='ls -lA'
alias rm='rm -iv'
alias mv='mv -iv'
alias cp='cp -iv'
alias crontab='crontab -i'
alias man='env LANG=C man'
alias diffy='diff -y -W $COLUMNS'
alias emacs='emacs -nw'

# Add an "alert" function for long running commands.  Use like so:
#   sleep 10; alert
function alert ()
{
    local exval=$?
    local command="$(history | tail -n 1 | sed -e 's/^\s*[0-9]\+\s*//;s/^[0-9]\+-[0-9]\+-[0-9]\+_[0-9]\+:[0-9]\+:[0-9]\+\\\s\+//;s/[;&|]\s*alert\s*$//')"
    echo -en '\a'
    if test $exval -eq 0; then
        local message="alert: Command terminated normally.: $command"
        if test -t 1 && tput setaf 1 &>/dev/null; then
            if test "$(tput colors)" -eq 256; then
                echo -E "$(tput setaf 10)$message$(tput sgr0)"
            else
                echo -E "$(tput setaf 2)$message$(tput sgr0)"
            fi
        else
            echo -E "$message"
        fi
    else
        local message="alert: Command terminated abnormally with exit code \`$exval'.: $command"
        if test -t 1 && tput setaf 1 &>/dev/null; then
            if test "$(tput colors)" -eq 256; then
                echo -E "$(tput setaf 9)$message$(tput sgr0)"
            else
                echo -E "$(tput setaf 1)$message$(tput sgr0)"
            fi
        else
            echo -E "$message"
        fi
    fi
}

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

function lsless ()
{
    if [ ! -t 1 ]; then
        echo "error: not a tty" >&2
        return 1
    fi
    ls --color=always "$@" | less -R
}

function llless ()
{
    if [ ! -t 1 ]; then
        echo "error: not a tty" >&2
        return 1
    fi
    ll --color=always "$@" | less -R
}

function llaless ()
{
    if [ ! -t 1 ]; then
        echo "error: not a tty" >&2
        return 1
    fi
    lla --color=always "$@" | less -R
}

function diffyless ()
{
    if [ ! -t 1 ]; then
        echo "error: not a tty" >&2
        return 1
    fi
    diffy "$@" | less
}

function reatach ()
{
    "$HOME/.screen/reatach.sh" "$@"
}

case "$TERM" in
    screen*) alias fix-ssh-agent='"$HOME/.screen/rm_invalid_session_dirs.sh"; [ -f "$HOME/.screen/sessions/$STY/fix-ssh-agent.sh" ] && . "$HOME/.screen/sessions/$STY/fix-ssh-agent.sh"';;
    *) ;;
esac

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
#    ;;
#*)
#    ;;
#esac

# check whether `bash-completion` includes `git-completion`.
if type -t __git_ps1 >/dev/null; then
    has_git_completion=yes
fi

case "$TERM" in
    xterm*|rxvt*|screen*)
        if [ "$color_prompt" = yes ]; then
            if [ "$has_git_completion" = yes ]; then
                PS1='\n${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1)\[\033[00m\]\$ '
            else
                PS1='\n${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
            fi
        else
            if [ "$has_git_completion" = yes ]; then
                PS1='\n${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1)\$ '
            else
                PS1='\n${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
            fi
        fi
        ;;
    *) ;;
esac
unset color_prompt force_color_prompt
unset has_git_completion

# Configurations to establish TeX Live environment.
case "$TERM" in
    screen*) ;;
    *)
        export INFOPATH="${INFOPATH:+$INFOPATH:}/usr/local/texlive/2013/texmf-dist/doc/info"
        export MANPATH="$MANPATH:/usr/local/texlive/2013/texmf-dist/doc/man"
        export PATH="${PATH:+$PATH:}/usr/local/texlive/2013/bin/x86_64-linux"
        ;;
esac

case "$TERM" in
    screen*) ;;
    *)
        if [ -f /etc/redhat-release ]; then
            yum check-update
        fi
        ;;
esac

case "$TERM" in
    screen*) ;;
    *)
        screen -q -ls
        if [ $? -ne 9 ]; then
            echo -e '\e[36m'
            screen -ls
            echo -en '\e[m'
        fi
        ;;
esac
