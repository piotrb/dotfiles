# Path the bin folder automatically inside projects
export PATH=./bin:$PATH

if [ -e ~/.rbenv/bin/rbenv ]; then
  export PATH=$HOME/.rbenv/bin:$PATH
  eval "$(rbenv init -)"
fi