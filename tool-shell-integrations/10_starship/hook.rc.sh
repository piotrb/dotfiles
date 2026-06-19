if [ $current_shell = "zsh" ]; then
    eval "$(starship init zsh)"
elif [ $current_shell = "bash" ]; then
    eval "$(starship init bash)"
fi