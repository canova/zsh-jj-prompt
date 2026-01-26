# zsh-jj-prompt

<img width="713" height="101" alt="zsh-jj-prompt" src="https://github.com/user-attachments/assets/f1857b13-0eeb-47ae-9af2-3231e6e29e77" />

A zsh plugin for [Jujutsu (jj)](https://github.com/martinvonz/jj) version control system, providing prompt functions similar to oh-my-zsh's git prompt.

## Features

- **Change ID**: Display short change ID (configurable length, default 8 chars)
- **Bookmarks**: Show bookmarks on the current commit
- **Ancestor Bookmarks**: Show nearest ancestor bookmark with distance (e.g., `main~3`)
- **Status Indicators**:
  - `!` - Conflict (merge conflicts present)
  - `∅` - Empty description (commit message needed)
  - `⇔` - Divergent (multiple commits with same change_id)
- **Async Prompts**: Non-blocking prompt updates for smooth UX
- **Fully Configurable**: All display options via theme variables
- **Git Fallback**: Automatically shows git prompt when not in a jj repository
- **oh-my-zsh Compatible**: Follows oh-my-zsh plugin conventions

## Installation

### oh-my-zsh

1. Clone this repository into your oh-my-zsh custom plugins directory:

```bash
git clone https://github.com/canova/zsh-jj-prompt ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-jj-prompt
```

2. Add `zsh-jj-prompt` to your plugins array in `~/.zshrc`:

```bash
plugins=(... zsh-jj-prompt)
```

3. Restart your shell or run:

```bash
source ~/.zshrc
```

### Standalone (without oh-my-zsh)

Source the plugin file directly in your `~/.zshrc`:

```bash
source /path/to/zsh-jj-prompt.plugin.zsh
```

Note: Async support requires oh-my-zsh. Without it, the plugin runs in synchronous mode.

## Usage

### Drop-in Replacement (Default, Recommended)

By default, the plugin works as a drop-in replacement for `git_prompt_info`. It automatically overrides your theme's git prompt function to show jj information in jj repositories and git information in git repositories. **No theme modifications needed!**

Just install the plugin and your existing theme will work with both jj and git repos automatically.

If you want to disable this behavior and use explicit `jj_prompt_info()` calls instead, set this in your `~/.zshrc` **before** loading the plugin:

```bash
# Disable drop-in replacement mode.
ZSH_THEME_JJ_OVERRIDE_GIT_PROMPT=false

# Then load plugins.
plugins=(... zsh-jj-prompt)
```

### Explicit Usage

If you've disabled the drop-in mode, add the `jj_prompt_info()` function to your prompt. The plugin follows the same pattern as oh-my-zsh's git plugin.

**Note**: The plugin automatically falls back to `git_prompt_info()` when not in a jj repository, so you can use `jj_prompt_info()` everywhere and it will show the appropriate prompt.

### Examples

Add to your theme or `~/.zshrc`:

```bash
# Left prompt
PROMPT+=' $(jj_prompt_info)'

# Right prompt
RPROMPT='$(jj_prompt_info)'

# Individual components
PROMPT+='$(jj_change_id) $(jj_bookmarks) $(jj_prompt_status)'
```

## Output Examples

- `jj:(qpvuntsm main) ` - On main bookmark
- `jj:(kmkuslsw main~3) ` - 3 commits after main
- `jj:(sqpnquxw) [!]` - Conflicted, no bookmarks
- `jj:(mzvwutvl trunk) [∅⇔]` - Empty description and divergent

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

# Drop-in replacement mode: override git_prompt_info (default: true)
ZSH_THEME_JJ_OVERRIDE_GIT_PROMPT=true
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
# Status wrapper start (default: [)
ZSH_THEME_JJ_PROMPT_STATUS_START="["

# Status wrapper end (default: ])
ZSH_THEME_JJ_PROMPT_STATUS_END="]"

# Conflict indicator (default: !)
ZSH_THEME_JJ_PROMPT_CONFLICT="!"

# Empty description indicator (default: ∅)
ZSH_THEME_JJ_PROMPT_EMPTY="∅"

# Divergent indicator (default: ⇔)
ZSH_THEME_JJ_PROMPT_DIVERGENT="⇔"
```

### Example Custom Configuration

```bash
# Minimal style - bookmarks only
ZSH_THEME_JJ_SHOW_CHANGE_ID=false
ZSH_THEME_JJ_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_JJ_PROMPT_CLEAN=""
```

## Performance

The plugin uses async prompts by default (requires zsh 5.0.6+) for non-blocking updates. To improve performance in large repositories, disable ancestor bookmarks:

```bash
ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS=false
```

## Troubleshooting

### Plugin doesn't show up

1. Verify jj is installed: `which jj`
2. Test the function directly: `jj_prompt_info`
3. Check you're in a jj repository: `jj status`

### Slow prompt

Disable ancestor bookmarks in large repositories:
```bash
ZSH_THEME_JJ_SHOW_ANCESTOR_BOOKMARKS=false
```

### Async not working

Requires oh-my-zsh and zsh 5.0.6+. Check your version: `zsh --version`

## Requirements

- [Jujutsu (jj)](https://github.com/martinvonz/jj) installed
- zsh 5.0.6+ and oh-my-zsh (for async support)

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
