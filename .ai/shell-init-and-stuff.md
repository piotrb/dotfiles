# Shell Init & Tool Integration - Context for Claude Code

## Environment
- Targets: WSL2 Ubuntu, native Linux amd64, native Linux arm64, macOS arm64
- Shell: zsh primary, bash compatible
- Dotfiles at ~/dotfiles, symlinked configs
- Modular rc system: ~/.profile.rc.d/*.{zsh,sh} loaded from ~/.zshrc
- Plugin list: ~/.zsh_plugins.txt managed by antidote

## Problems Solved

### 1. Windows PATH injection (FIXED)
- WSL2 was injecting ~60 Windows /mnt/c/... paths into $PATH
- `_path_commands` completion was crawling these over 9P filesystem causing 10s tab hangs
- Fix: `/etc/wsl.conf` with `[interop] appendWindowsPath = false`
- Manually re-added needed Windows paths (e.g. VS Code via wrapper script at ~/.local/bin/code)

### 2. Double compinit (FIXED)
- mattmc3/zephyr completion plugin + custom zz_compinit.zsh were both calling compinit
- zz_compinit.zsh was over-engineered for macOS/Homebrew multi-user scenarios, irrelevant on Linux
- Fix: deleted zz_compinit.zsh entirely, let zephyr handle compinit with:
  `zstyle ':zephyr:plugin:completion' use-cache yes`

### 3. P10k instant prompt ordering (FIXED)
- Was at bottom of .zshrc, after antidote load and profile.rc.d sourcing
- Moved to very top of .zshrc

### 4. Tool shell integration script (IN PROGRESS)
- Custom modular system at ~/dotfiles/tool-shell-integrations/
- Each integration is a directory with optional detect.* and hook.{env,rc}.{sh,zsh} files
- Loaded via ~/.profile.rc.d/zzz_tool-shell-integrations.sh

## Startup Time Progress
- Original: ~3400ms
- After Windows PATH removal: ~1484ms
- After compinit fix: ~993ms
- After bash→zsh subshell in detect: ~295ms
- Current bottleneck: _hook_shell_integrations ~164ms (remaining subshell forks)

## Tool Shell Integration System

### Directory structure
~/dotfiles/tool-shell-integrations/
  00_paths/
  1_mise/
  2_homebrew/
  9_p10k/
  atuin/
  aws/
  direnv/
  docker/
  git/
  golang/
  go-task/
  granted/
  janeseal/
  java/
  k8s/
  kiro/
  kubectl-krew/
  node/
  pi/
  python/
  rust/
  spacelift/
  terraform/
  vim/
  z_1password-cli/
  zz_ssh/
  helpers.sh

### Detection convention
- detect.command — contains binary name, checked via `command -v` (POSIX, no fork)
- detect.path — contains file path (supports leading ~ expanded via `${path/#\~/$HOME}`), checked via `[[ -e path ]]`
- detect.env — contains VAR=value, checked via `${(P)var}` in zsh / `${!var}` in bash
- detect.sh — fallback shell script, run via `( . detect.sh )` subshell (still a fork)
- no detect file — always enabled

### Migration status
- kiro → detect.env (TERM_PROGRAM=kiro) ✓
- 2_homebrew → detect.path (/opt/homebrew/bin/brew) ✓
- mise, direnv, atuin, kubectl-krew, granted, go-task → detect.command ✓

### Current helpers.sh state
Key functions:
- `_detect_integration $dir` — runs appropriate detection, logs via _debug, returns 0/1
- `_hook_shell_integration_single $dir $hook_type` — sources hook.{type}.sh and hook.{type}.$current_shell
- `_hook_shell_integration_detect $dir $hook_type` — runs detect then hooks if detected
- `_hook_shell_integrations $dir $hook_type` — iterates dirs with portable `*/` glob

Key decisions made:
- bash + zsh compatible throughout (bash 4+ required for declare -A)
- No subprocess for detect.command/detect.path/detect.env — uses `read -r var < file` (builtin redirect, no fork)
- detect.sh still uses a subshell fork (fallback only, no current users)
- No find subprocess — uses `"$dir"/*/` glob with `[[ -d ]]` guard (portable, no fork)
- current_shell variable set inline at source time (no subshell)
- `_debug()` writes to ~/.shell-debug-log.txt
- `_detect_integration` produces single log line: "name (via method) detected/not detected"
- Tilde expansion in detect.path via `${path/#\~/$HOME}` (portable bash/zsh)
- detect.env indirect expansion: `${(P)var}` in zsh, `${!var}` in bash

### zzz_tool-shell-integrations.sh current state
Still uses old get_shell_integrations_dir() with subshell forks (dirname, realpath).
Needs replacing with zsh-native (realpath assumed available on all platforms):
  TOOL_SHELL_INTEGRATIONS_DIR=${${(%):-%x}:A:h:h}/tool-shell-integrations
Note: for bash compat a BASH_SOURCE-based equivalent is also needed.

### Known remaining issue
- On "both" hook type, env pass runs before mise activates
- Tools installed via mise (atuin, direnv) fail detection on env pass
- They succeed on rc pass because mise env hook has run by then
- Numbered prefixes (1_mise, 2_homebrew) handle ordering but detection timing is still an issue
- Needs solution: possibly skip detection on env pass for mise-managed tools,
  or re-hash commands after mise env hook runs via `rehash`

## Current .zshrc structure
```zsh
# 1. P10k instant prompt (FIRST)
# 2. zmodload zsh/zprof (temporary, for profiling)
# 3. antidote source + load
# 4. unset ZSH_AUTOSUGGEST_USE_ASYNC
# 5. /etc/profile.d/* sourcing
# 6. ~/.profile.rc.d/* sourcing (includes zzz_tool-shell-integrations.sh)
# 7. zprof (temporary)
```

## Remaining work
1. Replace get_shell_integrations_dir in zzz_tool-shell-integrations.sh with fork-free path (zsh + bash variants)
2. Fix mise-managed tool detection timing (rehash after mise env hook?)
3. Remove zprof lines from .zshrc when done
4. Consider deferring non-critical integrations with zsh-defer
