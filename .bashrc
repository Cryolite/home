# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

ulimit -c unlimited
unset TMOUT
export PATH="$HOME/.local/bin${PATH:+:$PATH}"

#if [ -f /etc/debian_version ] && grep -Fq 'squeeze/sid' /etc/debian_version; then
#    export LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LIBRARY_PATH:+:$LIBRARY_PATH}"
#    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
#fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

if ! locale | grep -Eq '^LC_CTYPE=.*\.(UTF-8|utf-8|UTF8|utf8)'; then
    echo -e "\e[91m\`LC_CTYPE' should be set to \`*.UTF-8' in order to\
 properly handle non-ascii characters.\e[m"
fi

export EDITOR='emacs -nw'

if [[ -t 0 ]]; then
  stty stop undef
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=100000
HISTTIMEFORMAT='%Y/%m/%d %T  '

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [[ -z ${debian_chroot:-} && -r /etc/debian_chroot ]]; then
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

if [[ -n $force_color_prompt ]]; then
    if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# enable color support of ls and also add handy aliases
if [[ -x /usr/bin/dircolors ]]; then
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
alias diffy='diff -y -W $COLUMNS'
alias time='/usr/bin/time'
alias screen='screen -U'
alias emacs='emacs -nw'

# Add an "alert" function for long running commands.  Use like so:
#   sleep 10; alert
function alert ()
{
    local exval=$?
    local command="$(history | tail -n 1\
 | sed -e 's/^\s*[0-9]\+\s*//;s@^[0-9]\+/[0-9]\+/[0-9]\+\s\+[0-9]\+:[0-9]\+:[0-9]\+\s\+@@;s/[;&|]\s*alert\s*$//')"
    echo -en '\a'
    if (( "$exval" == 0 )); then
        local message="alert: Command terminated normally: $command"
        if [[ -t 1 ]] && tput setaf 1 &>/dev/null; then
            if (( "$(tput colors)" == 256 )); then
                echo -E "$(tput setaf 10)$message$(tput sgr0)"
            else
                echo -E "$(tput setaf 2)$message$(tput sgr0)"
            fi
        else
            echo -E "$message"
        fi
    else
        local message="alert: Command terminated abnormally with exit status \`$exval': $command"
        if [[ -t 1 ]] && tput setaf 1 &>/dev/null; then
            if (( "$(tput colors)" == 256 )); then
                echo -E "$(tput setaf 9)$message$(tput sgr0)"
            else
                echo -E "$(tput setaf 1)$message$(tput sgr0)"
            fi
        else
            echo -E "$message"
        fi
    fi
}

function time-n-alert ()
{
    /usr/bin/time "$@"; alert
}

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

function lsless ()
{
    if [[ ! -t 1 ]]; then
        echo "error: not a tty" >&2
        return 1
    fi
    ls --color=always "$@" | less -R
}

function llless ()
{
    if [[ ! -t 1 ]]; then
        echo "error: not a tty" >&2
        return 1
    fi
    ll --color=always "$@" | less -R
}

function llaless ()
{
    if [[ ! -t 1 ]]; then
        echo "error: not a tty" >&2
        return 1
    fi
    lla --color=always "$@" | less -R
}

function grepless ()
{
    if [[ ! -t 1 ]]; then
        echo 'error: not a tty' >&2
    fi
    grep --color=always "$@" | less -R
}

function fgrepless ()
{
    if [[ ! -t 1 ]]; then
        echo 'error: not a tty' >&2
    fi
    fgrep --color=always "$@" | less -R
}

function egrepless ()
{
    if [[ ! -t 1 ]]; then
        echo 'error: not a tty' >&2
    fi
    egrep --color=always "$@" | less -R
}

function diffyless ()
{
    if [[ ! -t 1 ]]; then
        echo "error: not a tty" >&2
        return 1
    fi
    diffy "$@" | less
}

function fix-environment ()
{
    if ! declare -p STY &>/dev/null; then
        local error_message="\`fix-environment' is called in a terminal other than GNU screen."
        if [[ -t 2 ]] && type -t tput >/dev/null; then
            if (( "$(tput colors)" == 256 )); then
                echo "$(tput setaf 9)$error_message$(tput sgr0)" >&2
            else
                echo "$(tput setaf 1)$error_message$(tput sgr0)" >&2
            fi
        else
            echo "$error_message" >&2
        fi
        return 1
    fi

    if [[ ! -f ~/.screen/sessions/$STY/fix-environment.sh ]]; then
        local error_message="\`~/.screen/sessions/$STY/fix-environment.sh'\
 does not exist. Resume this GNU screen session by \`reattach'."
        if [[ -t 2 ]] && type -t tput >/dev/null; then
            if (( "$(tput colors)" == 256 )); then
                echo "$(tput setaf 9)$error_message$(tput sgr0)" >&2
            else
                echo "$(tput setaf 1)$error_message$(tput sgr0)" >&2
            fi
        else
            echo "$error_message" >&2
        fi
        return 1
    fi

    "$HOME/.screen/rm-stale-session-dirs.sh"
    . "$HOME/.screen/sessions/$STY/fix-environment.sh"
}

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

# Set up `PS1`.
ps1='\n${debian_chroot:+($debian_chroot)}'

case "$TERM" in
xterm*|putty*|rxvt*|screen*)
    if [[ $color_prompt == yes ]]; then
        ps1+='\[\033[92m\]\u@\h\[\033[00m\]:\[\033[96m\]\w\[\033[00m\]'
    else
        ps1+='\u@\h:\w'
    fi
    ;;
*) ;;
esac

unset color_prompt force_color_prompt

case "$TERM" in
xterm*|putty*|rxvt*|screen*)
    # check whether `bash-completion` includes `git-completion`.
    if type -t __git_ps1 >/dev/null; then
        ps1+='$(__git_ps1)'
    elif [[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]]; then
        # For CentOS 7.
        . /usr/share/git-core/contrib/completion/git-prompt.sh
        ps1+='$(__git_ps1)'
    fi
esac

if declare -p STY &>/dev/null; then
    # The current interactive shell is running on a window of a GNU
    # `screen` session. The following configuration of prompts (and
    # `DEBUG` trap in older Bash below 4.4) sets up the title (see
    # https://www.gnu.org/software/screen/manual/html_node/Naming-Windows.html
    # for detail) and the hardstatus (see
    # https://www.gnu.org/software/screen/manual/html_node/Hardstatus.html
    # for detail) of the window. The title and hardstatus are set to
    # short and detailed descriptions of the state of the shell,
    # respectively.
    #
    # The following explains how it works.
    #
    # Immediately after reading a command line but before it is actually
    # executed, `~/.screen/ps0-hook.py` is executed. In older Bash below
    # 4.4, this script is executed by `DEBUG` trap (See
    # https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-trap
    # for detail). In Bash 4.4 or later, it is executed by a command
    # substitution in `PS0` environment variable (see
    # https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-PS0
    # and https://www.gnu.org/software/bash/manual/html_node/Interactive-Shell-Behavior.html
    # for detail). This script parses the contents of the files
    # `<(history 1)` and `<(jobs)`. Then, it sets the window title to a
    # short description of the job that is about to be executed by a
    # command line and the window hardstatus to a detailed description.
    # This is done by printing the escape sequences
    # `<ESC>k<window title><ESC>\` (see
    # https://www.gnu.org/software/screen/manual/html_node/Naming-Windows.html
    # for detail) and `<ESC>_<window hardstatus><ESC>\` (see
    # https://www.gnu.org/software/screen/manual/html_node/Hardstatus.html
    # for detail) to the standard output, i.e., the GNU screen's tty.
    # These sequences are not visible at all. Therefore, it never
    # disturb the console display.
    #
    # After execution of a command completes and it exits, the value of
    # `PS1` is expanded and displayed. The value includes
    # `\[<ESC>kbash<ESC>\\\]` and `\[<ESC>_\u@\H:\w<ESC>\\\]` (see
    # https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
    # for detail). These are not visible at all but reset the title and
    # hardstatus to `bash` and `<user>@<host>:/path/to/working/dir`,
    # respectively. Therefore, while the shell prompt is displayed and
    # no command is running, the title and hardstatus are set to `bash`
    # and `<user>@<host>:/path/to/working/dir`, repectively.

    if (( ${BASH_VERSINFO[0]} <= 3 || ${BASH_VERSINFO[0]} == 4 && ${BASH_VERSINFO[1]} < 4 )); then
        # `PS0` is available only in Bash 4.4 and later. Fall back to
        # `DEBUG` trap.
        # `<(history 1)` and `<(jobs)` cannot be used because it breaks
        # pipes due to a bug in Bash 4.2.
        trap '~/.screen/ps0-hook.py\
 --history-line-header "\s*\d+\s+\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\s+"\
 --wrapping-command time "$(history 1)" "$(jobs)"' DEBUG
    else
        PS0='\[$(~/.screen/ps0-hook.py\
 --history-line-header "\\s*\\d+\\s+\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}\\s+"\
 --wrapping-command time "$(history 1)" "$(jobs)")\]'
    fi

    # See https://www.gnu.org/software/screen/manual/html_node/Dynamic-Titles.html
    ps1+='\[\ekbash\e\\\]'
    # See https://www.gnu.org/software/screen/manual/html_node/Hardstatus.html
    ps1+='\[\e_\u@\H:\w\e\\\]'
fi

PS1="$ps1"'\$ '
unset ps1

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
        if [[ -f /etc/redhat-release ]]; then
            yum check-update
        fi
        ;;
esac

case "$TERM" in
    screen*) ;;
    *)
        screen -q -ls
        if (( $? != 9 )); then
            echo -e '\e[96m'
            screen -ls
            echo -en '\e[m'
        fi
        ;;
esac
