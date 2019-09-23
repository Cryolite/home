# ~/.bashrc: executed by bash(1) for non-login shells.
# See /usr/share/doc/bash/examples/startup-files (in the package
# bash-doc) for examples.



########################################################################
#                                                                      #
# Common configuration for both interactive and non-interactive shells #
#                                                                      #
########################################################################

# Prohibit core dump files to be created.
ulimit -c 0

# Disable timeout.
unset TMOUT

# Add `~/.local/bin` to `PATH` environment variable.
export PATH=$HOME/.local/bin${PATH:+:$PATH}

#if [ -f /etc/debian_version ] && grep -Fq 'squeeze/sid' /etc/debian_version; then
#    export LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LIBRARY_PATH:+:$LIBRARY_PATH}"
#    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
#fi



# If not running interactively, don't do anything.
case $- in
    *i*) ;;
      *) return;;
esac



########################################################################
#                                                                      #
# Terminal                                                             #
#                                                                      #
########################################################################

# Validate `TERM` environment variable, and change its value to a
# fallback one if necessary and possible.
if declare -p TERM &>/dev/null; then
    # Check whether the value of `TERM` environment variable is valid by
    # finding a matching terminfo entry.
    if ! infocmp &>/dev/null; then
        declare -a fallback_terms
        case "$TERM" in
        xterm-direct)
            fallback_terms+=(xterm-direct xterm-256color xterm)
            ;;
        xterm-256color)
            fallback_terms+=(xterm-256color xterm)
            ;;
        xterm-*|xterm)
            fallback_terms+=(xterm)
            ;;
        putty-256color)
            fallback_terms+=(putty-256color xterm-256color putty xterm)
            ;;
        putty-*|putty)
            fallback_terms+=(putty xterm)
            ;;
        mintty-direct)
            fallback_terms+=(mintty-direct xterm-direct mintty xterm-256color xterm)
            ;;
        mintty-*|mintty)
            fallback_terms+=(mintty xterm-256color xterm)
            ;;
        screen.xterm-256color)
            fallback_terms+=(screen.xterm-256color screen-256color screen)
            ;;
        screen.xterm-*)
            fallback_terms+=(screen)
            ;;
        screen.putty-256color)
            fallback_terms+=(screen.putty-256color screen.xterm-256color screen-256color screen.putty screen)
            ;;
        screen.putty-*|screen.putty)
            fallback_terms+=(screen.putty screen)
            ;;
        screen-256color)
            fallback_terms+=(screen-256color screen)
            ;;
        screen-*|screen)
            fallback_terms+=(screen)
            ;;
        *)
            ;;
        esac

        for t in "${fallback_terms[@]}"; do
            if infocmp "$t" &>/dev/null; then
                fallback_term=$t
                break
            fi
        done
        unset t
        unset fallback_terms
        if declare -p fallback_term &>/dev/null; then
            echo -E "WARNING: TERM=${TERM}: Could not find any matching\
 terminfo entry on this machine. Therefore, fall back to\
 \`$fallback_term'." >&2
            export TERM=$fallback_term
            unset fallback_term
        else
            echo -E "ERROR: TERM=${TERM}: Could not find neither\
 matching nor fallback terminfo entry on this machine." >&2
            return 1
        fi
    fi
fi


function _show_error_message ()
{
    if [[ -t 2 ]]; then
        if (( "$(tput colors)" == 16777216 )); then
            echo -E "$(tput setaf 0xFF0000)$1$(tput sgr0)" >&2
        elif (( "$(tput colors)" == 256 || "$(tput colors)" == 16 )); then
            echo -E "$(tput setaf 9)$1$(tput sgr0)" >&2
        elif (( "$(tput colors)" == 8 )); then
            echo -E "$(tput setaf 1)$1$(tput sgr0)" >&2
        else
            echo -E "$1" >&2
        fi
    else
        echo -E "$1" >&2
    fi
}


#=======================================================================
# Prepare `TERM` environment variable for GNU Screen
#=======================================================================
if declare -p SCREEN_TERM &>/dev/null; then
    :
elif infocmp "screen.$TERM" &>/dev/null; then
    export SCREEN_TERM=screen.$TERM
elif (( "$(tput colors)" >= 256 )); then
    export SCREEN_TERM=screen-256
else
    export SCREEN_TERM=screen
fi


# Disable STOP key.
if [[ -t 0 ]]; then
  stty stop undef
fi


# Text handled on the console is assumed to be encoded in UTF-8.
# Therefore, check if the encoding specified in the value of `LC_CTYPE`
# is UTF-8.
if ! locale | grep -Eq '^LC_CTYPE=.*\.(UTF-8|utf-8|UTF8|utf8)'; then
    _show_error_message "WARNING: \`LC_CTYPE' should be set to\
 \`*.UTF-8' in order to properly handle non-ascii characters."
fi



########################################################################
#                                                                      #
# History                                                              #
#                                                                      #
########################################################################

# Don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options.
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it.
shopt -s histappend

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1).
HISTSIZE=100000
HISTFILESIZE=100000
HISTTIMEFORMAT='%Y/%m/%d %T  '

# Ignore some controlling instructions.  `HISTIGNORE` is a
# colon-delimited list of patterns which should be excluded.  The '&' is
# a special pattern which suppresses duplicate entries.
#export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
#export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls' # Ignore the ls command as well

# Uncomment the following line in order to immediately append a command
# run by a bash shell on a host to the history of other bash shells
# running on the same host.
#PROMPT_COMMAND=${PROMPT_COMMAND}${PROMPT_COMMAND:+; }'history -a; history -c; history -r'



########################################################################
#                                                                      #
# Other shell options                                                  #
#                                                                      #
########################################################################

# Don't wait for job termination notification.
#set -o notify

# Don't use ^D to exit.
#set -o ignoreeof

# Check the window size after each command and, if necessary, update the
# values of LINES and COLUMNS.
shopt -s checkwinsize

# Use case-insensitive filename globbing.
#shopt -s nocaseglob

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

export EDITOR='emacs -nw'

# Make less more friendly for non-text input files, see lesspipe(1).
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"



########################################################################
#                                                                      #
# Aliases                                                              #
#                                                                      #
########################################################################

# If these are enabled they will be used instead of any instructions
# they may mask.  For example, alias rm='rm -i' will mask the rm
# application.  To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.

# Enable color support of `ls` and also add handy aliases.
if [[ -x /usr/bin/dircolors ]]; then
    unset LS_COLORS
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    fi
    # `DIR_COLORS.256color` is not my preference.
    #if [[ -z $LS_COLORS && -r /etc/DIR_COLORS.256color ]] && (( "$(tput colors)" >= 256 )); then
    #    eval "$(dircolors -b /etc/DIR_COLORS.256color)"
    #    if [[ -z $LS_COLORS ]]; then
    #        eval "$(TERM=xterm-256color dircolors -b /etc/DIR_COLORS.256color)"
    #    fi
    #fi
    if [[ -z $LS_COLORS && -r /etc/DIR_COLORS ]]; then
        eval "$(dircolors -b /etc/DIR_COLORS)"
        if [[ -z $LS_COLORS ]]; then
            eval "$(TERM=xterm-256color dircolors -b /etc/DIR_COLORS)"
        fi
    fi
    if [[ -z $LS_COLORS ]]; then
        eval "$(dircolors -b)"
    fi

    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias cd='pushd'
alias p='popd'

# Some more `ls` aliases.
alias ll='ls -l'
alias la='ls -A'
alias lla='ls -lA'

alias rm='rm -iv'
alias mv='mv -iv'
alias cp='cp -iv'

# Default to human readable figures.
alias df='df -h'
alias du='du -h'

alias crontab='crontab -i'
alias diffy='diff -y -W $COLUMNS'

# `/usr/bin/time` can print much more usable information than bash's
# `time` builtin.  However, it is not available on Cygwin.
[[ -x /usr/bin/time ]] && alias time='/usr/bin/time'

alias screen='screen -U'
alias emacs='emacs -nw'

# Alias definitions.
# You may want to put all your additions into a separate file like
# `~/.bash_aliases`, instead of adding them here directly.  See
# `/usr/share/doc/bash-doc/examples` in the bash-doc package.
if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi



########################################################################
#                                                                      #
# Functions.                                                           #
#                                                                      #
########################################################################

# Add an "alert" function for long running commands.  Use like so:
#   sleep 10; alert
function alert ()
{
    local exit_status=$?
    local command="$(history | tail -n 1\
 | LANG=C.UTF-8 sed -e 's/^\s*[0-9]\+\s*//;
s@^[0-9]\+/[0-9]\+/[0-9]\+\s\+[0-9]\+:[0-9]\+:[0-9]\+\s\+@@;
s/\s*[;&|]\s*alert\s*$//')"
    echo -en '\a'
    if (( "$exit_status" == 0 )); then
        local message="alert: Command terminated normally: $command"
        if [[ -t 2 ]]; then
            if (( "$(tput colors)" == 16777216 )); then
                echo -E "$(tput setaf 0x00FF00)$message$(tput sgr0)" >&2
            elif (( "$(tput colors)" == 256 || "$(tput colors)" == 16 )); then
                echo -E "$(tput setaf 10)$message$(tput sgr0)" >&2
            elif (( "$(tput colors)" == 8 )); then
                echo -E "$(tput setaf 2)$message$(tput sgr0)" >&2
            else
                echo -E "$message" >&2
            fi
        else
            echo -E "$message" >&2
        fi
    else
        _show_error_message "alert: Command terminated abnormally with\
 exit status \`$exit_status': $command"
    fi
}

function time-n-alert ()
{
    time "$@"; alert
}

for c in ls ll lla grep fgrep egrep; do
    . /dev/stdin <<-EOF
        function ${c}less ()
        {
            if [[ ! -t 1 ]]; then
                echo -E 'ERROR: Not a tty.' >&2
                return 1
            fi
            if tput setaf 1 &>/dev/null; then
                ${c} --color=always "\$@" | less -R
            else
                ${c} "\$@" | less
            fi
        }
EOF
done

# Old versions of `diff` does not support for `--color` option.
for c in diff diffy; do
    . /dev/stdin <<-EOF
        function ${c}less ()
        {
            if [[ ! -t 1 ]]; then
                echo -E 'ERROR: Not a tty.' >&2
                return 1
            fi
            if ! ${c} --color=always /dev/null /dev/null &>/dev/null; then
                ${c} "\$@" | less
                return $?
            fi
            if tput setaf 1 &>/dev/null; then
                ${c} --color=always "\$@" | less -R
            else
                ${c} "\$@" | less
            fi
        }
EOF
done

unset c


# Some people use a different file for functions.
#if [[ -f ${HOME}/.bash_functions ]]; then
#  . "${HOME}/.bash_functions"
#fi



########################################################################
#                                                                      #
# Programmable completion                                              #
#                                                                      #
########################################################################

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in `/etc/bash.bashrc` and `/etc/profile`
# sources `/etc/bash.bashrc`).
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi



########################################################################
#                                                                      #
# Make SSH clients more convenient                                     #
#                                                                      #
########################################################################

#=======================================================================
# Always run `ssh-pageant` on Cygwin.
#=======================================================================

function _ssh_pageant ()
{
    if [[ ! -e ~/.ssh ]]; then
        if ! (umask 0077 && mkdir ~/.ssh); then
            _show_error_message 'ERROR: ~/.ssh: Failed to create a directory.'
            return 1
        fi
    fi
    if [[ ! -d ~/.ssh ]]; then
        _show_error_message 'ERROR: ~/.ssh: Not a directory.'
        return 1
    fi

    if [[ ! -e ~/.ssh/run ]]; then
        if ! (umask 0077 && mkdir ~/.ssh/run); then
            _show_error_message 'ERROR: ~/.ssh/run: Failed to create a directory.'
            return 1
        fi
    fi
    if [[ ! -d ~/.ssh/run ]]; then
        _show_error_message 'ERROR: ~/.ssh/run: Not a directory.'
        return 1
    fi

    eval `ssh-pageant -a ~/.ssh/run/agent -r`
    return $?
}

[[ $(uname) =~ ^CYGWIN && -x /usr/bin/ssh-pageant ]] && _ssh_pageant
unset _ssh_pageant


#=======================================================================
# Convenient functions for SSH clients and agents.
#=======================================================================

# The following function is designed to solve inconvenience caused by
# using SSH and GNU screen together.  Steps to reproduce the problem
# situation is as follows:
#
#   1. Login to a host via SSH with agent forwarding being enabled.
#   2. Start a new GNU screen session on the host.
#   3. Detach the session.
#   4. Logout from the host.
#   5. Login again to the host via SSH with agent forwarding being
#      enabled.
#   6. Reattach the previously created session.
#
# At this point, `SSH_AUTH_SOCK` in the GNU screen session refers to the
# socket created at the first login, which is stale in the second and
# subsequent logins.  Therefore, SSH agent forwarding is broken and no
# longer available in that session.
#
# Combining `reattach` script located at `~/.local/bin` and the
# following `fix-environment` function can solve the problem described
# above.  Steps to fix it is as follows:
#
#   1. In the second or subsequent logins, reattach a detached session
#      with `reattach` script.
#   2. Call `fix-environment` in the reattached session.
#
# The above steps fix the value of `SSH_AUTH_SOCK` and re-enable SSH
# agent forwarding in the session.
#
# Kerberos forwardable tickets suffer from the same problem.  `reattach`
# script combined with `fix-environment` function also solve the problem
# for tickets.
function fix-environment ()
{
    if ! declare -p STY &>/dev/null; then
        _show_error_message "ERROR: \`fix-environment' should be called\
 in a GNU screen."
        return 1
    fi

    if [[ ! -f ~/.screen/sessions/$STY/fix-environment.sh ]]; then
        _show_error_message "ERROR:\
 ~/.screen/sessions/$STY/fix-environment.sh: File does not exist.\
 Resume this GNU screen session by \`reattach'."
        return 1
    fi

    "$HOME/.screen/rm-stale-session-dirs.sh"
    . "$HOME/.screen/sessions/$STY/fix-environment.sh"
}



########################################################################
#                                                                      #
# Prompts                                                              #
#                                                                      #
########################################################################

# Set a fancy prompt (non-color, unless we know we "want" color).
case "$TERM" in
xterm-*|xterm) color_prompt=yes;;
putty-*|putty) color_prompt=yes;;
mintty-*|mintty) color_prompt=yes;;
screen.*|screen-*|screen) color_prompt=yes;;
*) ;;
esac

# Uncomment for a colored prompt, if the terminal has the capability;
# turned off by default to not distract the user: the focus in a
# terminal window should be on the output of commands, not on the
# prompt.
#force_color_prompt=yes

if [[ -n $force_color_prompt ]]; then
    if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and
        # such a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Set variable identifying the chroot you work in (used in the prompt
# below).
if [[ -z ${debian_chroot:-} && -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi


#=======================================================================
# Set up `PROMPT_COMMAND` environment variable.
#=======================================================================


#=======================================================================
# Set up `PS1` environment variable.
#=======================================================================

ps1='\n${debian_chroot:+($debian_chroot)}'

case "$TERM" in
xterm-*|xterm|rxvt-*|rxvt|putty-*|putty|mintty-*|mintty|screen.*|screen-*|screen)
    if [[ $color_prompt == yes ]]; then
        ps1+='\[\033[92m\]\u@\h\[\033[00m\]:\[\033[96m\]\w\[\033[00m\]'
    else
        ps1+='\u@\h:\w'
    fi
    ;;
*) ;;
esac

unset color_prompt force_color_prompt


#=======================================================================
# Git prompt.
#=======================================================================

case "$TERM" in
xterm-*|xterm|rxvt-*|rxvt|putty-*|putty|mintty-*|mintty|screen.*|screen-*|screen)
    # Check whether `bash-completion` includes `git-completion`.
    if [[ -r ~/.git-prompt.sh ]]; then
        # On Cygwin, `git-completion.sh` is not available.  Therefore,
        # assume that the user has their own copy of `git-completion.sh`
        # in their home directory.
        . ~/.git-prompt.sh
        ps1+='$(__git_ps1)'
    elif type -t __git_ps1 >/dev/null; then
        ps1+='$(__git_ps1)'
    elif [[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]]; then
        # For CentOS 7.
        . /usr/share/git-core/contrib/completion/git-prompt.sh
        ps1+='$(__git_ps1)'
    fi
    ;;
*) ;;
esac


#=======================================================================
# Hooks on prompting to maintain GNU screen's window title and status.
#=======================================================================

if declare -p STY &>/dev/null; then
    # The current interactive shell is running on a window of a GNU
    # `screen` session.  The following configuration of prompts (and
    # `DEBUG` trap in older Bash below 4.4) sets up the title (see
    # https://www.gnu.org/software/screen/manual/html_node/Naming-Windows.html
    # for detail) and the hardstatus (see
    # https://www.gnu.org/software/screen/manual/html_node/Hardstatus.html
    # for detail) of the window.  The title and hardstatus are set to
    # short and detailed descriptions of the state of the shell,
    # respectively.
    #
    # The following explains how it works.
    #
    # Immediately after reading a command line but before it is actually
    # executed, `~/.screen/ps0-hook.py` is executed.  In older Bash
    # below 4.4, this script is executed by `DEBUG` trap (See
    # https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-trap
    # for detail).  In Bash 4.4 or later, it is executed by a command
    # substitution in `PS0` environment variable (see
    # https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-PS0
    # and https://www.gnu.org/software/bash/manual/html_node/Interactive-Shell-Behavior.html
    # for detail).  This script parses output of `history 1` and `jobs`.
    # Then, it sets the window title to a short description of the job
    # that is about to be executed by a command line and the window
    # hardstatus to a detailed description.  This is done by printing
    # the escape sequences `<ESC>k<window title><ESC>\` (see
    # https://www.gnu.org/software/screen/manual/html_node/Naming-Windows.html
    # for detail) and `<ESC>_<window hardstatus><ESC>\` (see
    # https://www.gnu.org/software/screen/manual/html_node/Hardstatus.html
    # for detail) to the standard output, i.e., the GNU screen's tty.
    # These sequences are not visible on the console at all.  Therefore,
    # it never disturbs the console display.
    #
    # After execution of a command completes and it exits, the value of
    # `PS1` is expanded and displayed.  The value includes
    # `\[<ESC>kbash<ESC>\\\]` and `\[<ESC>_\u@\H:\w<ESC>\\\]` (see
    # https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
    # for details on escape sequences in prompt strings).  These are not
    # visible on the console at all but reset the title and hardstatus
    # to `bash` and `<user>@<host>:/path/to/working/dir`, respectively.
    # Therefore, while the shell prompt is being displayed and no
    # command is running, the title and hardstatus are set to `bash` and
    # `<user>@<host>:/path/to/working/dir`, repectively.

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
