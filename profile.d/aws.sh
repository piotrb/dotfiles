function _vault() {
  if [ -e  $AWS_VAULT_PROFILE ]; then
    echo "must set AWS_VAULT_PROFILE"
    return 1
  fi
  aws-vault exec $AWS_VAULT_PROFILE --session-ttl=3h --assume-role-ttl=4h -- "$@"
}

