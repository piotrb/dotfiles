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

## Quick Start: Adding a New Node/TypeScript Script

1. Navigate to `src/node/`
2. Create your TypeScript file in `src/your-script.ts`
3. Create an executable wrapper in `bin/your-script`
4. Run `./link.sh` to make it globally available
5. See [src/node/CLAUDE.md](src/node/CLAUDE.md) for complete instructions
