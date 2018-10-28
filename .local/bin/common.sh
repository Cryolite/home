# This Bash file is not designed to be called directly, but rather is read by
# `source` Bash builtin command in the very beginning of another Bash script.

function print-error-message ()
{
  if [[ -t 2 ]] && type -t tput >/dev/null; then
    if (( "$(tput colors)" == 256 )); then
      echo "$(tput setaf 9)$1$(tput sgr0)" >&2
    else
      echo "$(tput setaf 1)$1$(tput sgr0)" >&2
    fi
  else
    echo "$1" >&2
  fi
}

function die-with-logic-error ()
{
  set +x
  print-error-message "$(basename "${BASH_SOURCE[-1]}"): error: ${1-A logic error.}"
  exit 1
}

function die-with-user-error ()
{
  set +x
  print-error-message "$(basename "${BASH_SOURCE[-1]}"): error: $1"
  print-error-message "Try \`$(basename "${BASH_SOURCE[-1]}") --help' for more information."
  exit 1
}

function die-with-runtime-error ()
{
  set +x
  print-error-message "$(basename "${BASH_SOURCE[-1]}"): error: $1"
  exit 1
}

PS4='+${BASH_SOURCE[0]}:$LINENO: '
if [[ -t 1 ]] && type -t tput >/dev/null; then
  if (( "$(tput colors)" == 256 )); then
    PS4='$(tput setaf 10)'$PS4'$(tput sgr0)'
  else
    PS4='$(tput setaf 2)'$PS4'$(tput sgr0)'
  fi
fi

new_args=()
while (( $# > 0 )); do
  arg="$1"
  shift
  case "$arg" in
  --debug)
    debug=yes
    new_args+=("$@")
    break
    ;;
  --)
    new_args+=(-- "$@")
    break
    ;;
  *)
    new_args+=("$arg")
    ;;
  esac
done
set -- ${new_args[@]+"${new_args[@]}"}
unset new_args
if [[ ${debug-no} == yes || ${VERBOSE+DEFINED} == DEFINED ]]; then
  set -x
fi
unset debug

rollback_stack=()

function push_rollback_command ()
{
  if ! declare -p rollback_stack &>/dev/null; then
    die-with-logic-error "\`rollback_stack' is not defined. Perhaps \`push_rollback_command' is called in a subshell."
  fi
  rollback_stack+=("$1")
}

function rollback ()
{
  for (( i = ${#rollback_stack[@]} - 1; i >= 0; --i )); do
    eval "${rollback_stack[$i]}"
  done
  rollback_stack=()
}

trap rollback EXIT
