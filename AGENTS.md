# Dotfiles Repository

This repository contains personal dotfiles and utilities.

## Scripts and Utilities

### src/node/ - Node.js/TypeScript Scripts

**Use this folder when creating new Node.js or TypeScript scripts.**

The `src/node/` directory is set up for TypeScript development with:
- Full TypeScript toolchain with strict type checking
- ESLint configured with Airbnb style guide
- ts-node for direct TypeScript execution
- Automatic linking to `~/bin/` for global access

See [src/node/CLAUDE.md](src/node/CLAUDE.md) for detailed structure and instructions on adding new scripts.

### Other Source Directories

- `src/python/` - Python scripts and utilities
- `src/ruby/` - Ruby scripts and utilities

## bin/ launcher stubs (ruby / node / python)

Global commands for the `src/{ruby,node,python}` tools are **generated**, not
hand-maintained. `src/make_stubs.rb` indexes all three folders, writes a
launcher into `bin/<name>` for each command, links it into `~/bin`, and manages
the generated-stub block in `bin/.gitignore` (the stubs bake absolute,
per-machine paths, so they are never committed).

To add a command: create the source file (`src/ruby/commands/<name>/main.rb`,
`src/node/src/<name>.ts`, or `src/python/<name>.py`), then run
`ruby src/make_stubs.rb` with the repo's direnv environment active (it reads
`$VIRTUAL_ENV` for the python interpreter).

## Additional Context Files
@.ai/shell-init-and-stuff.md
