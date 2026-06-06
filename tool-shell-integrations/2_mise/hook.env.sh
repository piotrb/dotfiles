
if (realpath --version 2>/dev/null 1>/dev/null); then
    # on linux, realpath is the gnu one
    export MISE_GLOBAL_CONFIG_FILE=~/$(realpath "${TOOL_SHELL_INTEGRATIONS_DIR}/../mise/config.toml" --relative-to ~/)
elif (grealpath --version 2>/dev/null 1>/dev/null); then
    # on mac, with grealpath installed
    export MISE_GLOBAL_CONFIG_FILE=~/$(grealpath "${TOOL_SHELL_INTEGRATIONS_DIR}/../mise/config.toml" --relative-to ~/)
else
    export MISE_GLOBAL_CONFIG_FILE=${TOOL_SHELL_INTEGRATIONS_DIR}/../mise/config.toml
fi
if [ $current_shell = "zsh" ]; then
    eval "$(mise activate zsh)"
elif [ $current_shell = "bash" ]; then
    eval "$(mise activate bash)"
else
    eval "$(mise activate --shims)"
fi
