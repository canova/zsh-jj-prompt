# Jujutsu (jj) plugin for oh-my-zsh
# Provides prompt functions to display jj repository information.

autoload -Uz is-at-least

# The jj prompt's jj commands are read-only and should not interfere with other processes.
# We wrap in a local function to ensure consistent behavior.
function __jj_prompt_command() {
  command jj "$@" 2>/dev/null
}

# Check if we're in a jj repository.
function in_jj_repo() {
  __jj_prompt_command root &>/dev/null
  return $?
}

#
# Theme variable defaults
# Users can override these in their theme files.
#

# Display control.
: ${ZSH_THEME_JJ_SHOW_CHANGE_ID:=true}
: ${ZSH_THEME_JJ_SHOW_BOOKMARKS:=true}
: ${ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS:=true}
: ${ZSH_THEME_JJ_CHANGE_ID_LENGTH:=8}

# Formatting.
: ${ZSH_THEME_JJ_PROMPT_PREFIX:="%{$fg_bold[blue]%}jj:(%{$fg[red]%}"}
: ${ZSH_THEME_JJ_PROMPT_SUFFIX:="%{$reset_color%} "}
: ${ZSH_THEME_JJ_PROMPT_CLEAN:="%{$fg[blue]%})"}

# Status indicators.
: ${ZSH_THEME_JJ_PROMPT_CONFLICT:="!"}
: ${ZSH_THEME_JJ_PROMPT_EMPTY:="?"}
: ${ZSH_THEME_JJ_PROMPT_DIVERGENT:="⇔"}

#
# Internal async handler function.
# Outputs formatted prompt string with jj repository information.
#
function _omz_jj_prompt_info() {
  # Fast fail if not in jj repo.
  in_jj_repo || return 0

  # Single command to get core info (delimiter: |).
  # Format: change_id|bookmarks|conflict|empty_desc|divergent
  local jj_info=$(__jj_prompt_command log -r @ --no-graph -T \
    'change_id.short('${ZSH_THEME_JJ_CHANGE_ID_LENGTH}') ++ "|" ++
     bookmarks.map(|ref| ref.name()).join(",") ++ "|" ++
     if(conflict, "1", "") ++ "|" ++
     if(description == "", "1", "") ++ "|" ++
     if(divergent, "1", "")')

  # Check if command succeeded.
  [[ -n "$jj_info" ]] || return 0

  # Parse fields using zsh field splitting.
  local -a fields
  fields=("${(@s/|/)jj_info}")
  local change_id="${fields[1]}"
  local bookmarks="${fields[2]}"
  local has_conflict="${fields[3]}"
  local is_empty="${fields[4]}"
  local is_divergent="${fields[5]}"

  # Get ancestor bookmarks if enabled and no direct bookmarks.
  local ancestor_bookmarks=""
  if [[ "$ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS" != "false" && -z "$bookmarks" ]]; then
    # Find nearest ancestor bookmark (exclude @ itself).
    local ancestor_name=$(__jj_prompt_command log \
      -r "ancestors(@) & bookmarks() & ~@" \
      --no-graph --limit 1 -T \
      'bookmarks.map(|ref| ref.name()).join(",")')

    if [[ -n "$ancestor_name" ]]; then
      # Calculate distance using separate command.
      # Count commits between ancestor bookmark and @.
      local distance=$(__jj_prompt_command log \
        -r "${ancestor_name}..@" \
        --no-graph -T 'commit_id ++ "\n"' | wc -l | xargs)

      if [[ "$distance" -gt 0 ]]; then
        bookmarks="${ancestor_name}"
        ancestor_bookmarks="~${distance}"
      fi
    fi
  fi

  # Build status string.
  local jj_status=""
  [[ -n "$has_conflict" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_CONFLICT"
  [[ -n "$is_empty" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_EMPTY"
  [[ -n "$is_divergent" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_DIVERGENT"

  # Format output.
  local output="$ZSH_THEME_JJ_PROMPT_PREFIX"

  # Add change ID if enabled.
  if [[ "$ZSH_THEME_JJ_SHOW_CHANGE_ID" != "false" ]]; then
    output+="${change_id:gs/%/%%}"
  fi

  # Add bookmarks if enabled and present.
  if [[ "$ZSH_THEME_JJ_SHOW_BOOKMARKS" != "false" ]]; then
    if [[ -n "$bookmarks" ]]; then
      # Add space before bookmarks if change_id was shown.
      [[ "$ZSH_THEME_JJ_SHOW_CHANGE_ID" != "false" ]] && output+=" "
      output+="${bookmarks:gs/%/%%}${ancestor_bookmarks:gs/%/%%}"
    fi
  fi

  # Close the prompt or add clean indicator.
  if [[ -n "$jj_status" ]]; then
    output+="%{$fg[blue]%}) [$jj_status]"
  else
    output+="$ZSH_THEME_JJ_PROMPT_CLEAN"
  fi

  output+="$ZSH_THEME_JJ_PROMPT_SUFFIX"

  echo -n "$output"
}

#
# Async setup following oh-my-zsh git.zsh pattern.
#
if zstyle -t ':omz:alpha:lib:jj' async-prompt \
  || { is-at-least 5.0.6 && zstyle -T ':omz:alpha:lib:jj' async-prompt }; then

  # Async mode: function reads from async output.
  function jj_prompt_info() {
    if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_jj_prompt_info]}" ]]; then
      echo -n "${_OMZ_ASYNC_OUTPUT[_omz_jj_prompt_info]}"
    fi
  }

  # Register async handler on first precmd where jj_prompt_info is used.
  function _defer_async_jj_register() {
    case "${PS1}:${PS2}:${PS3}:${PS4}:${RPROMPT}:${RPS1}:${RPS2}:${RPS3}:${RPS4}" in
    *(\$\(jj_prompt_info\)|\`jj_prompt_info\`)*)
      _omz_register_handler _omz_jj_prompt_info
      ;;
    esac
    add-zsh-hook -d precmd _defer_async_jj_register
    unset -f _defer_async_jj_register
  }

  precmd_functions=(_defer_async_jj_register $precmd_functions)

else
  # Synchronous fallback for older zsh versions.
  function jj_prompt_info() {
    _omz_jj_prompt_info
  }
fi

#
# Additional helper functions.
#

# Get just the status indicators.
function jj_prompt_status() {
  in_jj_repo || return 0

  local jj_info=$(__jj_prompt_command log -r @ --no-graph -T \
    'if(conflict, "1", "") ++ "|" ++
     if(description == "", "1", "") ++ "|" ++
     if(divergent, "1", "")')

  [[ -n "$jj_info" ]] || return 0

  local -a fields
  fields=("${(@s/|/)jj_info}")
  local has_conflict="${fields[1]}"
  local is_empty="${fields[2]}"
  local is_divergent="${fields[3]}"

  local jj_status=""
  [[ -n "$has_conflict" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_CONFLICT"
  [[ -n "$is_empty" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_EMPTY"
  [[ -n "$is_divergent" ]] && jj_status+="$ZSH_THEME_JJ_PROMPT_DIVERGENT"

  [[ -n "$jj_status" ]] && echo -n "$jj_status"
}

# Get just the change ID.
function jj_change_id() {
  in_jj_repo || return 0

  local change_id=$(__jj_prompt_command log -r @ --no-graph -T \
    'change_id.short('${ZSH_THEME_JJ_CHANGE_ID_LENGTH}')')

  [[ -n "$change_id" ]] && echo -n "$change_id"
}

# Get just the bookmarks.
function jj_bookmarks() {
  in_jj_repo || return 0

  local bookmarks=$(__jj_prompt_command log -r @ --no-graph -T \
    'bookmarks.map(|ref| ref.name()).join(",")')

  [[ -n "$bookmarks" ]] && echo -n "$bookmarks"
}
