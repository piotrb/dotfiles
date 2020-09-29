# load profile scripts
if [ -d $HOME/.profilerc.d ]; then
  for i in $HOME/.profilerc.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

