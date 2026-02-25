if [ "$current_shell" = "zsh" ]; then
    if [ "$CURSOR_AGENT" = "1" ] || [ "$CLAUDECODE" = "1" ]; then
        # Unset direnv vars before hooking to ensure clean state
        unset DIRENV_DIFF DIRENV_DIR DIRENV_FILE DIRENV_WATCHES
        old_direnv_config=$DIRENV_CONFIG
        export DIRENV_CONFIG=$TOOL_SHELL_INTEGRATIONS_DIR/direnv
        eval "$(direnv hook zsh)"
        cd .
        # direnv status
        export DIRENV_CONFIG=$old_direnv_config
    fi
fi
