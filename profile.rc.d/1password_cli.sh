if [ -e ~/.config/op/plugins.sh ]; then
  source ~/.config/op/plugins.sh
fi

if [ -e /opt/homebrew/bin/op ]; then
  op daemon -d
fi
