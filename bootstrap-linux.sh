#!/usr/bin/bash

set -e

if [ ! -e ~/.local/bin/mise ]; then
	# install Mise
	curl https://mise.run | sh
fi

eval "$(~/.local/bin/mise activate --shims)"

mise install gh

if ! gh auth status; then
	gh auth login
fi

mise install

ruby install.rb
