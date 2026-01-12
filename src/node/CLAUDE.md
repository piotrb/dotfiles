# Node/TypeScript Scripts

This folder contains Node.js and TypeScript utilities and scripts for the dotfiles repository.

## Overview

This is a TypeScript project configured for creating command-line utilities. Scripts are written in TypeScript in the `src/` directory, with executable wrappers in `bin/` that use ts-node to run them directly without requiring compilation.

## Configuration

- **TypeScript**: Configured for ES5 target with strict type checking
- **ESLint**: Uses Airbnb base style guide with TypeScript support
- **Dependencies**: lodash, random-seed, typescript
- **Dev Dependencies**: Full TypeScript toolchain, ESLint, Prettier, ts-node

## How It Works

1. TypeScript source files go in `src/`
2. Executable wrapper scripts go in `bin/`
3. Wrapper scripts use `ts-node` to run TypeScript directly
4. Run `link.sh` to symlink scripts from `bin/` to `~/bin/` for global access

## Example: project-name-generator

Generates readable project names from version numbers (e.g., "1.2.3" → "Aged Art Band").

## Adding a New Script

1. Create your TypeScript file in `src/your-script.ts`
2. Create an executable wrapper in `bin/your-script`:
   ```bash
   #!/bin/bash
   function resolve_path {
     ruby -e 'resolved = File.symlink?(ARGV[0]) ? File.readlink(ARGV[0]) : ARGV[0]; puts File.expand_path(resolved)' "${1}"
   }
   abs=$(resolve_path "$BASH_SOURCE")
   cd $(dirname "$(dirname "${abs}"))
   ./node_modules/.bin/ts-node src/your-script.ts "$@"
   ```
3. Make it executable: `chmod +x bin/your-script`
4. Run `./link.sh` to make it globally available
5. Install dependencies if needed: `yarn add <package>`

## Development

```bash
# Install dependencies
yarn install

# Run a script directly
./node_modules/.bin/ts-node src/your-script.ts

# Link scripts to ~/bin/
./link.sh

# Lint code
yarn eslint src/
```
