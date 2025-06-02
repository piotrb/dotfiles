function get_shell_integrations_dir() {
    if [ -n "$BASH_SOURCE" ]; then
        echo $(dirname $(dirname $(realpath "${BASH_SOURCE[0]}")))/tool-shell-integrations
    elif [ -n "$ZSH_VERSION" ]; then
        echo $(dirname $(dirname $(realpath "${(%):-%x}")))/tool-shell-integrations
    fi
}

TOOL_SHELL_INTEGRATIONS_DIR=$(get_shell_integrations_dir)

. $TOOL_SHELL_INTEGRATIONS_DIR/helpers.sh

_hook_shell_integrations $TOOL_SHELL_INTEGRATIONS_DIR "env"
