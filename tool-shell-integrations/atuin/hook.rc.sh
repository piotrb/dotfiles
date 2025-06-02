if [ -n "$ZSH_VERSION" ]; then
    eval "$(atuin init zsh)"
elif [ -n "$BASH_VERSION" ]; then
    eval "$(atuin init bash)"
fi
