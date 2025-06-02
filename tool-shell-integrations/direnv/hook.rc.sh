if [ -n "$ZSH_VERSION" ]; then
    emulate zsh -c "$(direnv hook zsh)"
elif [ -n "$BASH_VERSION" ]; then
    eval "$(direnv hook bash)"
fi
