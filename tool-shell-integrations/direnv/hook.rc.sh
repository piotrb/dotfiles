if [ $current_shell = "zsh" ]; then
    emulate zsh -c "$(direnv hook zsh)"
elif [ $current_shell = "bash" ]; then
    eval "$(direnv hook bash)"
fi
