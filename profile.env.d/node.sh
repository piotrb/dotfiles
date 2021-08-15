export PATH=./node_modules/.bin:$PATH

if which nodenv 2>/dev/null 1>/dev/null; then
  eval "$(nodenv init -)"
  export PATH="$HOME/.nodenv/bin:$PATH"
fi


#export PATH=$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH
