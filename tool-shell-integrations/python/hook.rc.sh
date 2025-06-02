if [ -e ~/.python/bin ]; then
  export PATH=~/.python/bin:$PATH
fi

if [ -e ~/.local/bin ]; then
  export PATH=~/.local/bin:$PATH
fi
