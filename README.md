# zsh-jj

A zsh plugin for [Jujutsu (jj)](https://github.com/martinvonz/jj) version control system, providing prompt functions similar to oh-my-zsh's git prompt.

## Features

- **Change ID**: Display short change ID (configurable length, default 8 chars)
- **Bookmarks**: Show bookmarks on the current commit
- **Ancestor Bookmarks**: Show nearest ancestor bookmark with distance (e.g., `main~3`)
- **Status Indicators**:
  - `!` - Conflict (merge conflicts present)
  - `?` - Empty description (commit message needed)
  - `⇔` - Divergent (multiple commits with same change_id)
- **Async Prompts**: Non-blocking prompt updates for smooth UX
- **Fully Configurable**: All display options via theme variables
- **Git Fallback**: Automatically shows git prompt when not in a jj repository
- **oh-my-zsh Compatible**: Follows oh-my-zsh plugin conventions

## Installation

### oh-my-zsh

1. Clone this repository into your oh-my-zsh custom plugins directory:

```bash
git clone https://github.com/canova/zsh-jj ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/jujutsu
```

2. Add `jujutsu` to your plugins array in `~/.zshrc`:

```bash
plugins=(... jujutsu)
```

3. Restart your shell or run:

```bash
source ~/.zshrc
```

### Standalone (without oh-my-zsh)

Source the plugin file directly in your `~/.zshrc`:

```bash
source /path/to/jujutsu.plugin.zsh
```

Note: Async support requires oh-my-zsh's async infrastructure. Without oh-my-zsh, the plugin will run in synchronous mode.

## Usage

Add the `jj_prompt_info()` function to your prompt. The plugin follows the same pattern as oh-my-zsh's git plugin.

**Note**: The plugin automatically falls back to `git_prompt_info()` when not in a jj repository, so you can use `jj_prompt_info()` everywhere and it will show the appropriate prompt.

### Basic Example (Robbyrussell-style)

Add to your theme or `~/.zshrc`:

```bash
PROMPT='%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%}'
PROMPT+=' $(jj_prompt_info)'
```

### Right Prompt Example

```bash
RPROMPT='$(jj_prompt_info)'
```

### Using Individual Functions

```bash
# Just the change ID
PROMPT+='$(jj_change_id) '

# Just the bookmarks
PROMPT+='$(jj_bookmarks) '

# Just the status indicators
PROMPT+='$(jj_prompt_status)'
```

### Drop-in Replacement for git_prompt_info

If you want to use this plugin as a true drop-in replacement without modifying your existing theme, enable override mode in your `~/.zshrc` **before** loading the plugin:

```bash
# Enable drop-in replacement mode.
ZSH_THEME_JJ_OVERRIDE_GIT_PROMPT=true

# Then load plugins.
plugins=(... jujutsu)
```

With this enabled, your existing theme's `git_prompt_info` calls will automatically use jj in jj repositories and git in git repositories. No theme modifications needed!

## Output Examples

- `jj:(qpvuntsm main) ` - On main bookmark
- `jj:(kmkuslsw main~3) ` - 3 commits after main
- `jj:(sqpnquxw) [!]` - Conflicted, no bookmarks
- `jj:(mzvwutvl trunk) [?⇔]` - Empty description and divergent

## Configuration

Customize the prompt by setting these variables in your theme or `~/.zshrc` **before** the plugin loads:

### Display Control

```bash
# Show/hide components (default: true)
ZSH_THEME_JJ_SHOW_CHANGE_ID=true
ZSH_THEME_JJ_SHOW_BOOKMARKS=true
ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS=true

# Change ID length (default: 8)
ZSH_THEME_JJ_CHANGE_ID_LENGTH=8

# Drop-in replacement mode: override git_prompt_info (default: false)
ZSH_THEME_JJ_OVERRIDE_GIT_PROMPT=false
```

### Formatting

```bash
# Prefix at the beginning (default: blue "jj:(" + red)
ZSH_THEME_JJ_PROMPT_PREFIX="%{$fg_bold[blue]%}jj:(%{$fg[red]%}"

# Suffix at the end (default: reset color + space)
ZSH_THEME_JJ_PROMPT_SUFFIX="%{$reset_color%} "

# Clean state indicator (default: blue ")")
ZSH_THEME_JJ_PROMPT_CLEAN="%{$fg[blue]%})"
```

### Status Indicators

```bash
# Conflict indicator (default: !)
ZSH_THEME_JJ_PROMPT_CONFLICT="!"

# Empty description indicator (default: ?)
ZSH_THEME_JJ_PROMPT_EMPTY="?"

# Divergent indicator (default: ⇔)
ZSH_THEME_JJ_PROMPT_DIVERGENT="⇔"
```

### Example Custom Configuration

```bash
# Minimal style
ZSH_THEME_JJ_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_JJ_PROMPT_SUFFIX=" "
ZSH_THEME_JJ_PROMPT_CLEAN=""
ZSH_THEME_JJ_SHOW_CHANGE_ID=false

# Powerline style
ZSH_THEME_JJ_PROMPT_PREFIX="%{$bg[blue]%}%{$fg[black]%}  "
ZSH_THEME_JJ_PROMPT_SUFFIX="%{$reset_color%}%{$fg[blue]%}%{$reset_color%} "
ZSH_THEME_JJ_PROMPT_CLEAN=""
```

## Performance

The plugin uses async prompts by default (requires zsh 5.0.6+), providing non-blocking prompt updates:

- **Core info**: ~100-130ms (async, non-blocking)
- **Ancestor bookmarks**: +50-80ms (separate command)
- **Total**: ~150-210ms (acceptable for async prompt)

### Performance Tips

1. **Disable ancestor bookmarks** if you don't need them:
   ```bash
   ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS=false
   ```

2. **Reduce ancestor search depth**:
   ```bash
   ZSH_THEME_JJ_ANCESTOR_DEPTH=5
   ```

3. **Shorter change ID**:
   ```bash
   ZSH_THEME_JJ_CHANGE_ID_LENGTH=6
   ```

## Troubleshooting

### Plugin doesn't show up

1. Verify you're in a jj repository:
   ```bash
   jj status
   ```

2. Test the function directly:
   ```bash
   jj_prompt_info
   ```

3. Check if jj is in PATH:
   ```bash
   which jj
   ```

### Prompt shows but looks wrong

1. Check your theme variables are set correctly.
2. Try resetting to defaults by unsetting all `ZSH_THEME_JJ_*` variables.
3. Make sure you're using zsh color codes correctly (`%{$fg[red]%}`).

### Slow prompt

1. Check if you're in a very large repository.
2. Disable ancestor bookmarks: `ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS=false`
3. Verify async mode is active (requires zsh 5.0.6+):
   ```bash
   zsh --version
   ```

### Async not working

Async support requires:
- oh-my-zsh installed
- zsh 5.0.6 or newer
- The plugin loaded via oh-my-zsh plugins array

## Requirements

- [Jujutsu (jj)](https://github.com/martinvonz/jj) installed and in PATH
- zsh 5.0.6+ (for async support)
- oh-my-zsh (recommended, for async support)

## Available Functions

- `jj_prompt_info()` - Full prompt with all information
- `jj_prompt_status()` - Status indicators only
- `jj_change_id()` - Change ID only
- `jj_bookmarks()` - Bookmarks only
- `in_jj_repo()` - Check if in a jj repository (returns 0/1)

## License

MIT

## Credits

Inspired by:
- [jj-starship](https://github.com/dmmulroy/jj-starship) - Jujutsu prompt integration
- [oh-my-zsh git plugin](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh) - Pattern and structure
