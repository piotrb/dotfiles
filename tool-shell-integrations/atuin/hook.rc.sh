if [ $current_shell = "zsh" ]; then
    eval "$(atuin init zsh)"
elif [ $current_shell = "bash" ]; then
    eval "$(atuin init bash)"
fi
