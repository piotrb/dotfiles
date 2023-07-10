function aw() {
  if [ -e  $AWS_VAULT_PROFILE ]; then
    echo "must set AWS_VAULT_PROFILE"
    return 1
  fi
  aws-vault exec $AWS_VAULT_PROFILE --duration=4h -- "$@"
}

export AWS_PAGER=""

# if on zsh, set up completion
if [ -n "$ZSH_VERSION" ]; then
  # use exec's completion syntax for aw
  compdef _exec aw
fi

