export PATH=./node_modules/.bin:$PATH

if [ -e ~/.nodenv/bin/nodenv ]; then
  export PATH=$HOME/.nodenv/bin:$PATH
  eval "$(nodenv init -)"
fi
