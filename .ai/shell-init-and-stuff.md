# Shell Init System

Canonical reference for how shells get configured in this repo. Keep this up to
date as the system evolves.

## TL;DR

Shell init is **pre-rendered at build time** instead of detected/assembled at
every shell start. A single config (`shell-init.yaml`) plus the
`tool-shell-integrations/` hooks are compiled by `bin/df-compile` into four flat
scripts under `~/.tsi/`, which the shell entry points just source.

```
shell-init.yaml ─┐
                 ├─►  bin/df-compile  ─►  ~/.tsi/{env,rc}.{sh,zsh}  ─►  sourced by zsh/bash
tool-shell-integrations/ ─┘            (detection BAKED at gen time)
```

Win: no per-tool `command -v` / `realpath` / subshell forks or directory walks
at shell startup. Cost: you must re-run `df-compile` when config/tools change.

## Targets & terminology

- **env** = environment (login/always): PATH, tool env. **rc** = runtime config
  (interactive): aliases, prompt, completion, keybindings.
- Two shell targets: **sh** (= bash) and **zsh**. So four outputs:
  `~/.tsi/env.sh`, `~/.tsi/env.zsh`, `~/.tsi/rc.sh`, `~/.tsi/rc.zsh`.

## Entry-point wiring (what sources what)

zsh maps perfectly onto env/rc; bash has no "always" file so `bashrc` is the
single source of truth and `bash_profile` just delegates to it.

```sh
# zshenv          ->  . ~/.tsi/env.zsh
# zshrc           ->  /etc/profile.d/*  (system, kept) ; then . ~/.tsi/rc.zsh
# bash_profile    ->  . ~/.bashrc
# bashrc          ->  . ~/.tsi/env.sh ; . ~/.tsi/rc.sh
```

Coverage: every interactive shell sources env once + rc once; a `zsh -c` script
gets env only (correct); bash non-interactive relies on inherited env. The old
`"both"` pass + `_HOOKED_INTEGRATIONS` dedup are gone — each file is sourced
exactly once, so there's nothing to dedup.

## `shell-init.yaml` — the config (source of truth)

Top-level `version`, plus ordered `env` and `rc` lists. **Order is load-bearing**
(see the PATH dance below). Each list entry is one of:

### Script block
```yaml
- name: dev env                # section header in the output
  if:                          # optional ITEM filters, ALL must pass (AND)
    shell: zsh                 #   zsh | bash | both (default; omit)
    command: starship          #   only if on PATH        (baked at gen time)
    path: /usr/libexec/x        #   only if path exists     (baked)
    env:                        #   only if env var matches (baked)
      TERM_PROGRAM: kiro
    sh: "test -d ~/foo"         #   only if snippet exits 0 (baked)
  cmd:                         # ordered list of commands
    - export FOO=bar
```

`cmd` is a list; each element is one of:

```yaml
cmd:
  - export FOO=bar                       # raw snippet (string), all shells
  - cmd: setopt EXTENDED_GLOB            # raw snippet, optionally shell-scoped
    shell: zsh
  - eval: starship init zsh              # wrapped as eval "$(starship init zsh)"
    shell: zsh
  - eval: starship init bash
    shell: bash
  - eval:                                # render at generation time:
      cmd: starship init zsh             #   run NOW, embed stdout verbatim
      render: true                       #   (default false = emit eval wrapper)
```

- Each element is a raw string, `{cmd, shell?}`, or `{eval, shell?}`.
- `eval` value is a string, or `{cmd, render}`; `render: true` executes the
  command at generation time and bakes its stdout in (no runtime fork; non-zero
  exit aborts the build).
- An element whose `shell` doesn't match the target is skipped; if nothing in
  `cmd` matches, the whole item is omitted (no empty section).
- Two levels of shell scoping: item-level `if: shell:` (whole item) and
  element-level `shell:` (per command, for per-shell `eval`s like starship).

### `tools` section (preferred for tool integrations)

A top-level `tools:` array mirrors the old `tool-shell-integrations/` folder —
each tool keeps its `env`/`rc` together with one shared `if`:

```yaml
tools:
  - name: atuin
    if:
      command: atuin          # gates the whole tool (both env and rc)
    env:                       # a cmd-list (same element schema as `cmd`)
      - export PATH="$HOME/.atuin/bin:$PATH"
    rc:
      - eval: atuin init zsh --disable-ai
        shell: zsh
      - eval: atuin init bash --disable-ai
        shell: bash
```

The array order drives render order for **both** levels (each level filters to
tools that define that section, so env-only and rc-only tools can interleave).
`env`/`rc` entries omit `name`/`if` (inherited from the tool).

### Anchors
```yaml
- anchor: tools                 # expands the `tools` array's env/rc sections
- anchor: tool-integrations     # expands the legacy folder hooks (below)
```

Baked conditions caveat: detection runs when `df-compile` runs. Tools that only
appear after another activates (mise-managed atuin/direnv) are included only if
present in the compiling shell — run `df-compile` from a fully-initialized shell.

## `tool-shell-integrations/` — the per-tool hooks

Rendered in place of `anchor: tool-integrations`. Each `<tool>/` dir has:

- **Detection** (first match wins): `detect.command` (binary, `command -v`),
  `detect.path` (path exists, `~` expanded), `detect.env` (`VAR=value`),
  `detect.sh` (snippet, exit 0), or none = always enabled.
- **Hooks**: `hook.{env,rc}.sh` (shared) and `hook.{env,rc}.{zsh,bash}`
  (shell-specific). Inside hooks, `current_shell` and
  `TOOL_SHELL_INTEGRATIONS_DIR` are available (emitted into the preamble only
  when referenced).

Dirs are processed in locale-collation order (numeric prefixes like `00_`, `1_`,
`2_` force ordering). The old `helpers.sh` runtime loader is **deleted** —
`df-compile` reimplements detection in Python.

## `bin/df-compile`

- Lives at `src/python/df-compile.py`, invoked via the generated `bin/df-compile`
  stub, which runs it under the repo's direnv venv python (so `import yaml`
  works — `pyyaml` is in `src/python/requirements.txt`).
- Flags: `--diff` (show changes vs current `~/.tsi`, write nothing),
  `--dry-run` (report only), `--verbose` (per-tool/item detection log),
  `--output-dir`, `--dotfiles-dir`.
- Generated files carry a `# AUTO-GENERATED … DO NOT EDIT` header (no timestamp,
  so `--diff` only shows real changes).

Regenerate with: `bin/df-compile`. Preview with: `bin/df-compile --diff`.

## bin/ launcher stubs

`src/make_stubs.rb` indexes `src/{ruby,node,python}`, writes a `bin/<name>`
launcher for each command, links it into `~/bin`, and manages a generated-stub
block in `bin/.gitignore` (stubs bake absolute per-machine paths → never
committed). It reads `$VIRTUAL_ENV` for the python interpreter and aborts if
direnv isn't active.

## The macOS PATH backup/restore dance

macOS `/etc/zprofile` runs `path_helper` *between* `zshenv` and `zshrc`,
clobbering PATH. So in `shell-init.yaml`:

- **env** ends with `export BACKUP_PATH=$PATH` (after the tool-integrations
  anchor, to capture the post-tool PATH).
- **rc** starts with `export PATH=$BACKUP_PATH; unset BACKUP_PATH` (restore
  first). On non-login shells this is a harmless round-trip.

This is why ordering in the YAML lists is load-bearing.

## Deferred / TODO

- Wire `df-compile` + venv `pip install` + `src/make_stubs.rb` into the
  bootstrap/install entry points (they're a bit chaotic; intentionally deferred).
  Until then, run them manually after changing config/tools.
- Consider folding more tool integrations into `shell-init.yaml` via `eval` +
  `render` where baking the output is preferable to a runtime fork.

## History (resolved earlier; kept for context)

- **WSL2 Windows PATH injection**: ~60 `/mnt/c/...` paths made completion crawl
  the 9P FS (10s tab hangs). Fixed via `/etc/wsl.conf` `[interop]
  appendWindowsPath = false`, re-adding only what's needed (e.g. VS Code).
- **Double compinit**: zephyr + a custom `zz_compinit.zsh` both ran compinit;
  the custom one was dropped (zephyr handles it with
  `zstyle ':zephyr:plugin:completion' use-cache yes`).
- **p10k instant prompt** must stay at the very top of `.zshrc`.
- **Startup time** fell from ~3400ms → ~300ms across these fixes; pre-rendering
  removes the remaining per-start detection/loop overhead.
- The previous system assembled hooks at runtime via
  `profile.{env,rc}.d/*_tool-shell-integrations.sh` + `helpers.sh` with a
  `"both"` pass and an env/rc dedup array. All of that is replaced by the
  pre-rendered pipeline above; `profile.{env,rc}.d/` were migrated into
  `shell-init.yaml` and removed.
```
