# shellcheck shell=zsh
# shellcheck disable=SC2039
#
# Authors: Praneet & Srirangarajan
#
# MIT License
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

# This program expects the user to set $GOTO_ENV_DIR for local environment, else stores aliases globally

goto() {
  # Path to store the previous db
  local prev_db_file="$HOME/.cache/goto/goto_prev_db"
  local db prev_db

  # Ensure the directory for the prev_db_file exists
  mkdir -p "$(dirname "$prev_db_file")"

  # Retrieve the previous db if it exists
  if [[ -f "$prev_db_file" ]]; then
    prev_db=$(<"$prev_db_file")
  else
    prev_db=""
  fi

  # Resolve the current db
  db=$(_goto_resolve_db)

  # Notify the user if there's a mode switch
  if [[ "$db" != "$prev_db" ]]; then
    if [[ "$db" == "$HOME/.config/goto" ]]; then
      echo "Currently using global aliases. Set GOTO_ENV_DIR to use aliases from a local environment\n"
    else
      echo "Switched to local environment: $(dirname "$db")\n"
    fi
    # Update the prev_db in the file
    echo "$db" > "$prev_db_file"
  fi

  # Process the goto subcommands.
  if [[ -z "$1" ]]; then
    _goto_usage
    return
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    -m|--mode)
      if [[ "$db" == "$HOME/.config/goto" ]]; then
        echo "Global"
      else
        echo "Local environment with path: $(dirname "$db")"
      fi
      ;;
    -c|--cleanup)
      _goto_cleanup
      ;;
    -r|--register)
      _goto_register_alias "$@"
      ;;
    -u|--unregister)
      _goto_unregister_alias "$@"
      ;;
    -p|--push)
      _goto_directory_push "$@"
      ;;
    -o|--pop)
      _goto_directory_pop
      ;;
    -l|--list)
      _goto_list_aliases "$db"
      ;;
    -x|--expand)
      _goto_expand_alias "$@"
      ;;
    -h|--help)
      _goto_usage
      ;;
    -v|--version)
      _goto_version
      ;;
    *)
      if [[ $# -gt 1 ]]; then
        local first_alias="$1"
        shift
        _goto_directory "$first_alias"
        for alias in "$@"; do
          local directory
          directory=$(_goto_find_alias_directory "$alias")
          if [[ -d "$directory" ]]; then
            # Open a new pane in zellij for each directory
            zellij action new-pane --cwd="$directory" --direction=down
          else
            _goto_error "Alias '$alias' does not exist or is not a valid directory"
          fi
        done
      else
        _goto_directory "$subcommand"
      fi
      ;;
  esac
}

# Helper function to resolve the database path and handle mode switching.
_goto_resolve_db() {
  local db
  if [[ -n "$GOTO_ENV_DIR" ]]; then
    if [[ -d "$GOTO_ENV_DIR" ]]; then
      db="$GOTO_ENV_DIR/.goto_aliases"
    else
      echo "ERROR: GOTO_ENV_DIR is set but is not a valid directory. (goto defaults back to global aliases)" 1>&2
      db="$HOME/.config/goto"
    fi
  else
    db="$HOME/.config/goto"
  fi
  echo "$db"
}

# Display usage information.
_goto_usage() {
  \cat <<USAGE
usage: goto [<option>] <alias> [<directory>]

OPTIONS:
  -m, --mode: Display the current mode
  -r, --register: Register an alias
  -u, --unregister: Unregister an alias
  -p, --push: Push the current directory onto the stack, then goto
  -o, --pop: Pop the top directory from the stack, then change to that directory
  -l, --list: List aliases
  -x, --expand: Expand an alias
  -c, --cleanup: Clean up non-existent directory aliases
  -h, --help: Prints this help
  -v, --version: Displays the version of the goto script
USAGE
}

# Display the script version.
_goto_version() {
  echo "goto version 1.1.0"
}

# Expands directory.
# Helpful for ~, ., .. paths
_goto_expand_directory() {
  builtin cd "$1" 2>/dev/null && pwd
}

# Register a new alias.
_goto_register_alias() {
  local db=$(_goto_resolve_db)

  if [[ $# -ne 2 ]]; then
    _goto_error "usage: goto -r|--register <alias> <directory>"
    return 1
  fi

  if ! [[ $1 =~ ^[[:alnum:]]+[a-zA-Z0-9_-]*$ ]]; then
    _goto_error "invalid alias - can start with letters or digits followed by letters, digits, hyphens or underscores"
    return 1
  fi

  local resolved
  resolved=$(_goto_find_alias_directory "$1")
  if [[ -n "$resolved" ]]; then
    _goto_error "alias '$1' exists"
    return 1
  fi

  local alias="$1"
  local directory
  directory=$(_goto_expand_directory "$2")
  if [[ -z "$directory" ]]; then
    _goto_error "failed to register '$alias' to '$2' - can't cd to directory"
    return 1
  fi
  local duplicate
  duplicate=$(_goto_find_duplicate "$directory")
  if [[ -n "$duplicate" ]]; then
    _goto_warning "duplicate alias(es) found: \\n$duplicate"
  fi

  echo "$alias $directory" >> "$db"
  echo "Alias '$alias' registered successfully."
}

# Unregisters the given alias.
_goto_unregister_alias() {
  local db=$(_goto_resolve_db)

  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto -u|--unregister <alias>"
    return 1
  fi

  local resolved
  resolved=$(_goto_find_alias_directory "$1")
  if [[ -z "$resolved" ]]; then
    _goto_error "alias '$1' does not exist"
    return 1
  fi

  local readonly GOTO_DB_TMP="$HOME/.goto_"
  # Delete entry from file.
  sed "/^$1 /d" "$db" > "$GOTO_DB_TMP" && mv "$GOTO_DB_TMP" "$db"
  echo "Alias '$1' unregistered successfully."
}

# Pushes the current directory onto the stack, then goto
_goto_directory_push() {
  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto -p|--push <alias>"
    return
  fi

  { pushd . || return; } 1>/dev/null 2>&1
  _goto_directory "$1"
}

# Pops the top directory from the stack, then goto
_goto_directory_pop() {
  { popd || return; } 1>/dev/null 2>&1
}

# Finds a registered alias directory
_goto_find_alias_directory() {
  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto <alias>"
    return
  fi

  local db=$(_goto_resolve_db)
  local alias=$1

  local resolved
  resolved=$(grep -e "^$alias " "$db" | cut -d' ' -f2-)
  echo "$resolved"
}

# Finds duplicate directories in alias registrations
_goto_find_duplicate() {
  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto <alias>"
    return
  fi

  local db=$(_goto_resolve_db)

  local directory
  directory=$1
  grep -e "$directory" "$db"
}

# Lists registered aliases.
_goto_list_aliases() {
  local db=$(_goto_resolve_db)
  local IFS=$' '
  if [[ -s "$db" ]]; then
    local maxlength=0
    while read -r name directory; do
      local length=${#name}
      if ((length > maxlength)); then
        maxlength=$length
      fi
    done < "$db"
    while read -r name directory; do
      printf "\e[1;36m%${maxlength}s  \e[0m%s\n" "$name" "$directory"
    done < "$db"
  else
    echo "You haven't configured any directory aliases yet."
  fi
}

# Expands a registered alias.
_goto_expand_alias() {
  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto -x|--expand <alias>"
    return
  fi

  local resolved

  resolved=$(_goto_find_alias_directory "$1")
  if [[ -z "$resolved" ]]; then
    _goto_error "alias '$1' does not exist"
    return
  fi

  echo "$resolved"
}

# Changes directory to alias
_goto_directory() {
  local db=$(_goto_resolve_db)
  
  if [[ $# -ne 1 ]]; then
    _goto_error "usage: goto <alias>"
    return
  fi

  local alias="$1"
  local directory
  directory=$(grep -e "^$alias " "$db" | cut -d' ' -f2-)
  if [[ -z "$directory" ]]; then
    _goto_error "alias '$alias' does not exist"
    return 1
  fi

  eval cd "$directory" || return 1
}

# Cleans up aliases that point to non-existent directories
_goto_cleanup() {
  local db=$(_goto_resolve_db)

  if [[ ! -f "$db" ]]; then
    _goto_error "No database file found at $db."
    return 1
  fi

  local temp_db
  temp_db=$(mktemp)

  local cleaned_count=0
  local total_count=0

  while read -r alias directory; do
    ((total_count++))
    if [[ -d "$directory" ]]; then
      echo "$alias $directory" >> "$temp_db"
    else
      _goto_warning "Removed alias '$alias' pointing to non-existent directory: $directory"
      ((cleaned_count++))
    fi
  done < "$db"

  mv "$temp_db" "$db"
  echo "Cleanup complete. Removed $cleaned_count invalid aliases out of $total_count total."
}


# Prints error messages.
_goto_error() {
  echo "$1" 1>&2
}

# Prints warning message
_goto_warning() {
  echo "$1" 1>&2
}

# Auto-completion for goto.
_goto_autocomplete() {
  local cur db
  cur="${words[-1]}"
  db=$(_goto_resolve_db)

  if [[ $cur == -* ]]; then
    _goto_complete_options
  else
    _goto_complete_aliases
  fi
}

# Completes options for goto.
_goto_complete_options() {
    _arguments -s -S \
        '--mode[Display the current mode]' \
        '--register[Register an alias]' \
        '--unregister[Unregister an alias]' \
        '--push[Push the current directory onto the stack, then goto]' \
        '--pop[Pop the top directory from the stack, then change to that directory]' \
        '--list[List aliases]' \
        '--expand[Expand an alias]' \
        '--cleanup[Clean up non-existent directory aliases]' \
        '--help[Prints the help section]' \
        '--version[Displays the version of the goto script]' \
}

# Completes aliases for goto.
_goto_complete_aliases() {
  local db=$(_goto_resolve_db)
  if [[ -f "$db" ]]; then
    # _values "aliases" \
    #     'root[come to root]' \
    #     'shit[come to root]' \

    compadd $(cut -d' ' -f1 "$db")
  fi
}

compdef _goto_autocomplete goto

