# if zsh, use zsh completion
if [ -n "$ZSH_VERSION" ]; then
  eval "$(task --completion zsh)"
fi

# if bash, use bash completion
if [ -n "$BASH_VERSION" ]; then
  eval "$(task --completion bash)"
fi
