#!/usr/bin/env python3
"""df-compile — pre-render shell integration scripts.

Reads shell-init.yaml and generates ~/.tsi/{env,rc}.{sh,zsh}.
Run via the bin/df-compile stub (uses the repo's direnv venv for pyyaml).
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit(
        "df-compile requires PyYAML. Run it via `bin/df-compile` (uses the repo's\n"
        "direnv venv), or install it: pip install pyyaml"
    )

# (level, shell) -> output filename
TARGETS = [
    ("env", "bash", "env.sh"),
    ("env", "zsh", "env.zsh"),
    ("rc", "bash", "rc.sh"),
    ("rc", "zsh", "rc.zsh"),
]

# Config file (source of truth), relative to the dotfiles repo root.
CONFIG_NAME = "shell-init.yaml"

# Shell-specific hook extensions per target shell.
def read_text(path):
    with open(path, "r") as f:
        return f.read()


def log(verbose, *args):
    if verbose:
        print("[df-compile]", *args, file=sys.stderr)


# --------------------------------------------------------------------------- #
# --------------------------------------------------------------------------- #
# Rendering
# --------------------------------------------------------------------------- #
WIDTH = 78
RULE = "=" * (WIDTH - 2)

def major_header(title):
    """A prominent full-width section divider."""
    return [f"# {RULE}", f"# {title}", f"# {RULE}"]



ALLOWED_IF_KEYS = {"shell", "command", "path", "env", "sh"}


def item_passes(item, target_shell, verbose, label="item"):
    """Evaluate an item's `if:` filters (AND). A missing `if`/key always passes.

    Supported keys:
      shell:   zsh | bash | both  — baked (scopes the target)
      command: binary name        — baked (must be on PATH at gen time)
      path:    file/dir path      — baked (must exist at gen time)
      sh:      shell snippet      — baked (must exit 0 at gen time)
      env:     {VAR: value}       — RUNTIME: emits a shell `if` wrapper
    """
    cond = item.get("if") or {}
    if not isinstance(cond, dict):
        sys.exit(f"shell-init.yaml: `if` must be a mapping, got {cond!r}")
    unknown = set(cond) - ALLOWED_IF_KEYS
    if unknown:
        sys.exit(f"shell-init.yaml: unknown `if` keys: {sorted(unknown)}")

    name = item.get("name", "(unnamed)")
    if not _shell_ok(cond.get("shell", "both"), target_shell):
        log(verbose, f"{label}:{name} skipped (if.shell != {target_shell})")
        return False

    # Baked checks only — env is handled at render time as a shell wrapper.
    checks = [
        ("command", lambda v: shutil.which(v) is not None),
        ("path", lambda v: os.path.exists(os.path.expanduser(v))),
        ("sh", _check_sh),
    ]
    for key, fn in checks:
        if key in cond and not fn(cond[key]):
            log(verbose, f"{label}:{name} skipped (if.{key} = false)")
            return False
    return True


def render_tools(tools, level, shell, verbose):
    """Render the `tools` array for one (level, shell).

    Each tool: {name, if?, env?: cmd-list, rc?: cmd-list}. The tool-level `if`
    gates the whole tool; its `env`/`rc` are cmd-lists (same element schema).
    """
    out = []
    for tool in tools:
        if not isinstance(tool, dict):
            sys.exit(f"shell-init.yaml: `tools` entries must be mappings, got {tool!r}")
        name = tool.get("name", "(unnamed)")
        if not item_passes(tool, shell, verbose, label="tool"):
            continue
        cmd_list = tool.get(level)
        if not cmd_list:
            continue
        text = render_cmd_list(cmd_list, shell)
        if text is None:
            log(verbose, f"tool:{name} {level} empty for {shell}")
            continue
        cond = tool.get("if") or {}
        text = env_guard(text, cond, name, verbose, label="tool")
        log(verbose, f"tool:{name} {level} rendered")
        out.append("")
        out.append("")
        out.extend(major_header(name))
        out.append(text)
    return out


def _shell_ok(shell, target_shell):
    return shell == "both" or shell == target_shell


def _parse_env_cond(spec):
    """Validate and return (var, value) from an if.env mapping."""
    if not isinstance(spec, dict) or len(spec) != 1:
        sys.exit(f"shell-init.yaml: `if.env` must be a single-key mapping e.g. {{TERM_PROGRAM: kiro}}, got {spec!r}")
    var, val = next(iter(spec.items()))
    return var, str(val)


def env_guard(text, cond, name, verbose, label="item"):
    """Wrap text in a runtime shell conditional if `if: env:` is present."""
    env_spec = cond.get("env") if cond else None
    if not env_spec:
        return text
    var, val = _parse_env_cond(env_spec)
    log(verbose, f"{label}:{name} wrapped in runtime env guard (${var} = {val!r})")
    indented = "\n".join(f"  {line}" if line else "" for line in text.split("\n"))
    return f'if [ "${var}" = "{val}" ]; then\n{indented}\nfi'


def _check_sh(script):
    try:
        return (
            subprocess.run(
                ["bash", "-c", script],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )
    except OSError:
        return False


SHELLS = {"zsh", "bash", "both"}
CMD_ELEMENT_KEYS = {"cmd", "eval", "shell"}


def render_cmd_list(cmd_list, target_shell):
    """Render a `cmd` list for this target shell, or None if it emits nothing.

    Each element is one of:
      "raw script"                       a raw shell snippet (all shells)
      {cmd: "raw script", shell: zsh}    raw snippet, optionally shell-scoped
      {eval: "command", shell: bash}     wrapped as eval "$(command)"
      {eval: {cmd: "command", render: true}}
                                         render=true runs the command at
                                         generation time and embeds its output
    Elements whose `shell` does not match the target are skipped.
    """
    if not isinstance(cmd_list, list):
        sys.exit(f"shell-init.yaml: `cmd` must be a list, got {cmd_list!r}")

    parts = []
    for el in cmd_list:
        text = _render_cmd_element(el, target_shell)
        if text is not None:
            parts.append(text)
    return "\n".join(parts) if parts else None


def item_body(item, target_shell):
    cmd_list = item.get("cmd")
    if cmd_list is None:
        sys.exit(f"shell-init.yaml: item {item.get('name', '(unnamed)')!r} has no `cmd`")
    return render_cmd_list(cmd_list, target_shell)


def _render_cmd_element(el, target_shell):
    if isinstance(el, str):
        return el.rstrip("\n")
    if not isinstance(el, dict):
        sys.exit(f"shell-init.yaml: cmd element must be a string or mapping, got {el!r}")

    unknown = set(el) - CMD_ELEMENT_KEYS
    if unknown:
        sys.exit(f"shell-init.yaml: unknown cmd element keys: {sorted(unknown)}")

    shell = el.get("shell", "both")
    if shell not in SHELLS:
        sys.exit(f"shell-init.yaml: invalid shell {shell!r} (zsh|bash|both)")
    if not _shell_ok(shell, target_shell):
        return None

    has_cmd, has_eval = "cmd" in el, "eval" in el
    if has_cmd == has_eval:
        sys.exit(f"shell-init.yaml: cmd element needs exactly one of cmd/eval: {el!r}")

    if has_cmd:
        return str(el["cmd"]).rstrip("\n")

    command, render = _resolve_eval(el["eval"])
    if not render:
        return f'eval "$({command})"'
    proc = subprocess.run(["bash", "-c", command], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(
            f"shell-init.yaml: render command failed (exit {proc.returncode}): {command}\n"
            f"{proc.stderr.strip()}"
        )
    return proc.stdout.rstrip("\n")


def _resolve_eval(ev):
    """An eval value is a string, or {cmd: ..., render: bool}. -> (command, render)."""
    if isinstance(ev, str):
        return (ev, False)
    if isinstance(ev, dict) and "cmd" in ev:
        return (ev["cmd"], bool(ev.get("render", False)))
    sys.exit(f"shell-init.yaml: invalid eval value {ev!r} (string or {{cmd, render}})")


def render_target(dotfiles_dir, level, shell, outfile, verbose, config):
    items = config.get(level) or []

    # Build the body first so the preamble can include only the helper
    # variables that the rendered hooks/scripts actually reference.
    body = []
    for item in items:
        if not isinstance(item, dict):
            sys.exit(f"shell-init.yaml: {level} entries must be mappings, got {item!r}")

        if "anchor" in item:
            anchor = item["anchor"]
            log(verbose, f"anchor:{anchor} expanded")
            if anchor == "tools":
                body.extend(render_tools(config.get("tools") or [], level, shell, verbose))
            else:
                sys.exit(f"shell-init.yaml: unknown anchor {anchor!r} (only 'tools' is supported)")
            continue

        name = item.get("name", "(unnamed)")
        if not item_passes(item, shell, verbose):
            continue

        text = item_body(item, shell)
        if text is None:
            log(verbose, f"item:{name} skipped (no body for {shell})")
            continue

        cond = item.get("if") or {}
        text = env_guard(text, cond, name, verbose)
        log(verbose, f"item:{name} rendered")
        body.append("")
        body.append("")
        body.extend(major_header(item.get("name", "(unnamed)")))
        body.append(text)
    body_text = "\n".join(body)

    preamble = []
    if "current_shell" in body_text:
        preamble.append(f'current_shell="{shell}"')
    if "DOTFILES_DIR" in body_text:
        preamble.append(f'DOTFILES_DIR="{dotfiles_dir}"')

    parts = [
        "# AUTO-GENERATED by df-compile -- DO NOT EDIT",
        "# regenerate with: df-compile  (src/python/df-compile.py)",
        f"# target: level={level} shell={shell} -> {outfile}",
        f"# source: {os.path.join(dotfiles_dir, CONFIG_NAME)}",
        "#",
        "# Detection was baked at generation time. Tools that only appear after",
        "# another tool activates (e.g. mise-managed) are included only if they",
        "# were present in the compiling shell's environment.",
    ]
    if preamble:
        parts.append("")
        parts.extend(preamble)
    parts.append(body_text)

    # Collapse any run of 3+ blank lines down to a single blank line, then
    # ensure a clean single trailing newline.
    text = "\n".join(parts)
    while "\n\n\n\n" in text:
        text = text.replace("\n\n\n\n", "\n\n\n")
    return text.strip("\n") + "\n"


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def default_dotfiles_dir():
    # This script lives at <repo>/src/python/df-compile.py
    here = os.path.realpath(__file__)
    return os.path.dirname(os.path.dirname(os.path.dirname(here)))


def load_config(dotfiles_dir):
    path = os.path.join(dotfiles_dir, CONFIG_NAME)
    if not os.path.isfile(path):
        sys.exit(f"config not found: {path}")
    with open(path) as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        sys.exit(f"{CONFIG_NAME}: top level must be a mapping")
    return data


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Pre-render shell integration scripts into ~/.tsi/.",
    )
    parser.add_argument(
        "--dotfiles-dir",
        default=default_dotfiles_dir(),
        help="Path to the dotfiles repo (default: resolved from this script).",
    )
    parser.add_argument(
        "--output-dir",
        default=os.path.expanduser("~/.tsi"),
        help="Where to write the generated files (default: ~/.tsi).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be written; write nothing.",
    )
    parser.add_argument(
        "--diff",
        action="store_true",
        help="Compare freshly generated output against the existing files "
        "(via 'diff -u') and print any differences; write nothing.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Log each detection result to stderr.",
    )
    args = parser.parse_args(argv)

    dotfiles_dir = os.path.realpath(os.path.expanduser(args.dotfiles_dir))
    output_dir = os.path.expanduser(args.output_dir)

    if not os.path.isdir(dotfiles_dir):
        parser.error(f"dotfiles dir not found: {dotfiles_dir}")

    config = load_config(dotfiles_dir)

    if args.diff:
        return run_diff(dotfiles_dir, output_dir, args.verbose, config)

    if not args.dry_run:
        os.makedirs(output_dir, exist_ok=True)

    for level, shell, fname in TARGETS:
        content = render_target(dotfiles_dir, level, shell, fname, args.verbose, config)
        dest = os.path.join(output_dir, fname)
        if args.dry_run:
            print(f"[dry-run] would write {dest} ({len(content)} bytes)")
        else:
            with open(dest, "w") as f:
                f.write(content)
            log(args.verbose, f"wrote {dest} ({len(content)} bytes)")

    if not args.dry_run:
        print(f"Generated {len(TARGETS)} files in {output_dir}")

    return 0


def run_diff(dotfiles_dir, output_dir, verbose, config):
    """Generate to a temp dir and diff against the existing files.

    Returns 1 if any target differs (or is missing), 0 if all match.
    """
    changed = False
    with tempfile.TemporaryDirectory(prefix="df-compile-") as tmp:
        for level, shell, fname in TARGETS:
            content = render_target(dotfiles_dir, level, shell, fname, verbose, config)
            new_path = os.path.join(tmp, fname)
            with open(new_path, "w") as f:
                f.write(content)

            dest = os.path.join(output_dir, fname)
            current = dest if os.path.exists(dest) else os.devnull
            result = subprocess.run(
                [
                    "diff", "-u",
                    "--label", f"a/{fname} (current)",
                    "--label", f"b/{fname} (generated)",
                    current, new_path,
                ],
                stdout=subprocess.PIPE,
                text=True,
            )
            if result.returncode != 0:
                changed = True
                sys.stdout.write(result.stdout)

    if not changed:
        print(f"No changes: generated output matches {output_dir}")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
