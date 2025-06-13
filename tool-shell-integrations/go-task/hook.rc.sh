# if zsh, use zsh completion
if [ $current_shell = "zsh" ]; then
  eval "$(task --completion zsh)"
fi

# if bash, use bash completion
if [ $current_shell = "bash" ]; then
  eval "$(task --completion bash)"
fi
