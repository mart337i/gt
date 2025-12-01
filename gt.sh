# shellcheck shell=bash
# shellcheck disable=SC2039
# SOURCE: https://github.com/iridakos/goto
# MIT License
#
# Copyright (c) 2025 Martin Egeskov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Changes to the given alias directory
# or executes a command based on the arguments.
gt()
{
  local target
  _gt_resolve_db

  if [ -z "$1" ]; then
    # display usage and exit when no args
    _gt_usage
    return
  fi

  subcommand="$1"
  shift
  case "$subcommand" in
    -c|--cleanup)
      _gt_cleanup "$@"
      ;;
    -r|--register) # Register an alias
      _gt_register_alias "$@"
      ;;
    -u|--unregister) # Unregister an alias
      _gt_unregister_alias "$@"
      ;;
    -p|--push) # Push the current directory onto the pushd stack, then gt
      _gt_directory_push "$@"
      ;;
    -o|--pop) # Pop the top directory off of the pushd stack, then change that directory
      _gt_directory_pop
      ;;
    -l|--list)
      _gt_list_aliases
      ;;
    -x|--expand) # Expand an alias
      _gt_expand_alias "$@"
      ;;
    -h|--help)
      _gt_usage
      ;;
    -v|--version)
      _gt_version
      ;;
    *)
      _gt_directory "$subcommand" "$@"
      ;;
  esac
  return $?
}

_gt_resolve_db()
{
  local CONFIG_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/gt"
  GT_DB="${GT_DB:-$CONFIG_DEFAULT}"
  GT_DB_CONFIG_DIRNAME=$(dirname "$GT_DB")
  if [[ ! -d "$GT_DB_CONFIG_DIRNAME" ]]; then
    mkdir "$GT_DB_CONFIG_DIRNAME"
  fi
  touch -a "$GT_DB"
}

_gt_usage()
{
  cat <<\USAGE
usage: gt [<option>] <alias> [<directory>]

default usage:
  gt <alias> - changes to the directory registered for the given alias

OPTIONS:
  -r, --register: registers an alias
    gt -r|--register <alias> <directory>
  -u, --unregister: unregisters an alias
    gt -u|--unregister <alias>
  -p, --push: pushes the current directory onto the stack, then performs gt
    gt -p|--push <alias>
  -o, --pop: pops the top directory from the stack, then changes to that directory
    gt -o|--pop
  -l, --list: lists aliases
    gt -l|--list
  -x, --expand: expands an alias
    gt -x|--expand <alias>
  -c, --cleanup: cleans up non existent directory aliases
    gt -c|--cleanup
  -h, --help: prints this help
    gt -h|--help
  -v, --version: displays the version of the gt script
    gt -v|--version
USAGE
}

# Displays version
_gt_version()
{
  echo "gt version 3.0.0"
}

# Expands directory.
# Helpful for ~, ., .. paths
_gt_expand_directory()
{
  builtin cd "$1" 2>/dev/null && pwd
}

# Lists registered aliases.
_gt_list_aliases()
{
  local IFS=$' '
  if [ -f "$GT_DB" ]; then
    local maxlength=0
    while read -r name directory; do
      local length=${#name}
      if [[ $length -gt $maxlength ]]; then
        local maxlength=$length
      fi
    done < "$GT_DB"
    while read -r name directory; do
      printf "\e[1;36m%${maxlength}s  \e[0m%s\n" "$name" "$directory"
    done < "$GT_DB"
  else
    echo "You haven't configured any directory aliases yet."
  fi
}

# Expands a registered alias.
_gt_expand_alias()
{
  if [ "$#" -ne "1" ]; then
    _gt_error "usage: gt -x|--expand <alias>"
    return
  fi

  local resolved

  resolved=$(_gt_find_alias_directory "$1")
  if [ -z "$resolved" ]; then
    _gt_error "alias '$1' does not exist"
    return
  fi

  echo "$resolved"
}

# Lists duplicate directory aliases
_gt_find_duplicate()
{
  local duplicates=

  duplicates=$(sed -n 's:[^ ]* '"$1"'$:&:p' "$GT_DB" 2>/dev/null)
  echo "$duplicates"
}

# Registers and alias.
_gt_register_alias()
{
  if [ "$#" -ne "2" ]; then
    _gt_error "usage: gt -r|--register <alias> <directory>"
    return 1
  fi

  if ! [[ $1 =~ ^[[:alnum:]]+[a-zA-Z0-9_-]*$ ]]; then
    _gt_error "invalid alias - can start with letters or digits followed by letters, digits, hyphens or underscores"
    return 1
  fi

  local resolved
  resolved=$(_gt_find_alias_directory "$1")

  if [ -n "$resolved" ]; then
    _gt_error "alias '$1' exists"
    return 1
  fi

  local directory
  directory=$(_gt_expand_directory "$2")
  if [ -z "$directory" ]; then
    _gt_error "failed to register '$1' to '$2' - can't cd to directory"
    return 1
  fi

  local duplicate
  duplicate=$(_gt_find_duplicate "$directory")
  if [ -n "$duplicate" ]; then
    _gt_warning "duplicate alias(es) found: \\n$duplicate"
  fi

  # Append entry to file.
  echo "$1 $directory" >> "$GT_DB"
  echo "Alias '$1' registered successfully."
}

# Unregisters the given alias.
_gt_unregister_alias()
{
  if [ "$#" -ne "1" ]; then
    _gt_error "usage: gt -u|--unregister <alias>"
    return 1
  fi

  local resolved
  resolved=$(_gt_find_alias_directory "$1")
  if [ -z "$resolved" ]; then
    _gt_error "alias '$1' does not exist"
    return 1
  fi

  # shellcheck disable=SC2034
  local GT_DB_TMP="$HOME/.gt_"
  readonly GT_DB_TMP
  # Delete entry from file.
  sed "/^$1 /d" "$GT_DB" > "$GT_DB_TMP" && mv "$GT_DB_TMP" "$GT_DB"
  echo "Alias '$1' unregistered successfully."
}

# Pushes the current directory onto the stack, then gt
_gt_directory_push()
{
  if [ "$#" -ne "1" ]; then
    _gt_error "usage: gt -p|--push <alias>"
    return
  fi

  { pushd . || return; } 1>/dev/null 2>&1

  _gt_directory "$@"
}

# Pops the top directory from the stack, then gt
_gt_directory_pop()
{
  { popd || return; } 1>/dev/null 2>&1
}

# Unregisters aliases whose directories no longer exist.
_gt_cleanup()
{
  if ! [ -f "$GT_DB" ]; then
    return
  fi

  while IFS= read -r i && [ -n "$i" ]; do
    echo "Cleaning up: $i"
    _gt_unregister_alias "$i"
  done <<< "$(awk '{al=$1; $1=""; dir=substr($0,2);
                    system("[ ! -d \"" dir "\" ] && echo " al)}' "$GT_DB")"
}

# Changes to the given alias' directory
_gt_directory()
{
  local alias_name="$1"
  local subdir=""
  
  # Check if the first argument contains a slash (alias/subpath format)
  if [[ "$alias_name" == */* ]]; then
    # Split into alias and subpath
    subdir="${alias_name#*/}"
    alias_name="${alias_name%%/*}"
  fi
  
  # If a second argument was provided, use it as subdir (overrides slash notation)
  [ -n "$2" ] && subdir="$2"
  
  # directly gt the special name that is unable to be registered due to invalid alias, eg: ~
  if ! [[ $alias_name =~ ^[[:alnum:]]+[a-zA-Z0-9_-]*$ ]]; then
    { builtin cd "$1" 2> /dev/null && return 0; } || \
    { _gt_error "Failed to gt '$1'" && return 1; }
  fi

  local target

  target=$(_gt_resolve_alias "$alias_name") || return 1

  # Append subpath if provided
  [ -n "$subdir" ] && target="$target/$subdir"

  builtin cd "$target" 2> /dev/null || \
    { _gt_error "Failed to gt '$target'" && return 1; }
}

# Fetches the alias directory.
_gt_find_alias_directory()
{
  local resolved

  resolved=$(sed -n "s/^$1 \\(.*\\)/\\1/p" "$GT_DB" 2>/dev/null)
  echo "$resolved"
}

# Displays the given error.
# Used for common error output.
_gt_error()
{
  (>&2 echo -e "gt error: $1")
}

# Displays the given warning.
# Used for common warning output.
_gt_warning()
{
  (>&2 echo -e "gt warning: $1")
}

# Displays entries with aliases starting as the given one.
_gt_print_similar()
{
  local similar

  similar=$(sed -n "/^$1[^ ]* .*/p" "$GT_DB" 2>/dev/null)
  if [ -n "$similar" ]; then
    (>&2 echo "Did you mean:")
    (>&2 column -t <<< "$similar")
  fi
}

# Fetches alias directory, errors if it doesn't exist.
_gt_resolve_alias()
{
  local resolved

  resolved=$(_gt_find_alias_directory "$1")

  if [ -z "$resolved" ]; then
    _gt_error "unregistered alias $1"
    _gt_print_similar "$1"
    return 1
  else
    echo "${resolved}"
  fi
}

# Completes the gt function with the available commands
_complete_gt_commands()
{
  local IFS=$' \t\n'

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "-r --register -u --unregister -p --push -o --pop -l --list -x --expand -c --cleanup -v --version" -- "$1"))
}

# Completes the gt function with the available aliases
_complete_gt_aliases()
{
  local IFS=$'\n' matches
  _gt_resolve_db

  # shellcheck disable=SC2207
  matches=($(sed -n "/^$1/p" "$GT_DB" 2>/dev/null))

  if [ "${#matches[@]}" -eq "1" ]; then
    # remove the filenames attribute from the completion method
    compopt +o filenames 2>/dev/null

    # if you find only one alias don't append the directory
    COMPREPLY=("${matches[0]// *}")
  else
    for i in "${!matches[@]}"; do
      # remove the filenames attribute from the completion method
      compopt +o filenames 2>/dev/null

      if ! [[ $(uname -s) =~ Darwin* ]]; then
        matches[i]=$(printf '%*s' "-$COLUMNS" "${matches[i]}")

        COMPREPLY+=("$(compgen -W "${matches[$i]}")")
      else
        COMPREPLY+=("${matches[$i]// */}")
      fi
    done
  fi
}

# Bash programmable completion for the gt function
_complete_gt_bash()
{
  local cur="${COMP_WORDS[$COMP_CWORD]}" prev

  if [ "$COMP_CWORD" -eq "1" ]; then
    # if we are on the first argument
    if [[ $cur == -* ]]; then
      # and starts like a command, prompt commands
      _complete_gt_commands "$cur"
    else
      # Check if current word contains a slash (alias/subpath format)
      if [[ $cur == */* ]]; then
        local alias_name="${cur%%/*}"
        local subpath="${cur#*/}"
        local alias_dir
        
        alias_dir=$(_gt_find_alias_directory "$alias_name")
        if [ -n "$alias_dir" ]; then
          local IFS=$'\n'
          local subdirs
          # Get subdirectories, preserving the alias/ prefix and adding trailing slash
          # shellcheck disable=SC2207
          COMPREPLY=($(cd "$alias_dir" 2>/dev/null && compgen -d -- "$subpath" | while read -r dir; do echo "$alias_name/$dir/"; done))
          compopt -o nospace 2>/dev/null
        fi
      else
        # and doesn't start as a command, prompt aliases
        _complete_gt_aliases "$cur"
      fi
    fi
  elif [ "$COMP_CWORD" -eq "2" ]; then
    # if we are on the second argument
    prev="${COMP_WORDS[1]}"

    if [[ $prev = "-u" ]] || [[ $prev = "--unregister" ]]; then
      # prompt with aliases if user tries to unregister one
      _complete_gt_aliases "$cur"
    elif [[ $prev = "-x" ]] || [[ $prev = "--expand" ]]; then
      # prompt with aliases if user tries to expand one
      _complete_gt_aliases "$cur"
    elif [[ $prev = "-p" ]] || [[ $prev = "--push" ]]; then
      # prompt with aliases only if user tries to push
      _complete_gt_aliases "$cur"
    else
      # check if prev is an alias, if so provide directory completion from that path
      local alias_dir
      alias_dir=$(_gt_find_alias_directory "$prev")
      if [ -n "$alias_dir" ]; then
        local IFS=$' \t\n'
        compopt -o nospace 2>/dev/null
        # Add trailing slash to directories for easy continuation
        # shellcheck disable=SC2207
        COMPREPLY=($(cd "$alias_dir" 2>/dev/null && compgen -d -- "$cur" | while read -r dir; do echo "$dir/"; done))
      fi
    fi
  elif [ "$COMP_CWORD" -eq "3" ]; then
    # if we are on the third argument
    prev="${COMP_WORDS[1]}"

    if [[ $prev = "-r" ]] || [[ $prev = "--register" ]]; then
      # prompt with directories only if user tries to register an alias
      local IFS=$' \t\n'

      # shellcheck disable=SC2207
      COMPREPLY=($(compgen -d -- "$cur"))
    fi
  fi
}

# Zsh programmable completion for the gt function
_complete_gt_zsh()
{
  local all_aliases=()
  _gt_resolve_db
  while IFS= read -r line; do
    all_aliases+=("$line")
  done <<< "$(sed -e 's/ /:/g' "$GT_DB" 2>/dev/null)"

  local state
  local -a options=(
    '(1)'{-r,--register}'[registers an alias]:register:->register'
    '(- 1 2)'{-u,--unregister}'[unregisters an alias]:unregister:->unregister'
    '(: -)'{-l,--list}'[lists aliases]'
    '(*)'{-c,--cleanup}'[cleans up non existent directory aliases]'
    '(1 2)'{-x,--expand}'[expands an alias]:expand:->aliases'
    '(1 2)'{-p,--push}'[pushes the current directory onto the stack, then performs gt]:push:->aliases'
    '(*)'{-o,--pop}'[pops the top directory from stack, then changes to that directory]'
    '(: -)'{-h,--help}'[prints this help]'
    '(* -)'{-v,--version}'[displays the version of the gt script]'
  )

  _arguments -C \
    "${options[@]}" \
    '1:alias:->aliases' \
    '2:dir:_files' \
  && ret=0

  case ${state} in
    (aliases)
      _describe -t aliases 'gt aliases:' all_aliases && ret=0
    ;;
    (unregister)
      _describe -t aliases 'unregister alias:' all_aliases && ret=0
    ;;
  esac
  return "$ret"
}

# shellcheck disable=SC2207
gt_aliases=($(alias | sed -n "s/.*\s\(.*\)='gt'/\1/p"))
gt_aliases+=("gt")

for i in "${gt_aliases[@]}"
	do
		# Register the gt completions.
	if [ -n "${BASH_VERSION}" ]; then
	  if ! [[ $(uname -s) =~ Darwin* ]]; then
	    complete -o filenames -F _complete_gt_bash "$i"
	  else
	    complete -F _complete_gt_bash "$i"
	  fi
	elif [ -n "${ZSH_VERSION}" ]; then
	  compdef _complete_gt_zsh "$i"
	else
	  echo "Unsupported shell."
	  exit 1
	fi
done
