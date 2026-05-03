
export MISE_GLOBAL_CONFIG_FILE=~/$(realpath "${TOOL_SHELL_INTEGRATIONS_DIR}/../mise/config.toml" --relative-to ~/)
eval "$(mise activate --shims)"
# if [ $current_shell = "zsh" ]; then
#     eval "$(mise activate zsh)"
# elif [ $current_shell = "bash" ]; then
#     eval "$(mise activate bash)"
# fi
