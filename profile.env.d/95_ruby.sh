#alias cucumber="spring_wrapper cucumber"
#alias rspec="spring_wrapper rspec"
#alias ph="bundle_wrapper ph"
#alias cap="bundle_wrapper cap"
#alias yard="bundle_wrapper yard"
#alias yardoc="bundle_wrapper yardoc"
#alias rake="spring_wrapper rake"
#alias rails="spring_wrapper rails"
#alias guard="spring_wrapper guard"
#alias rdbm="spring_wrapper rake db:migrate"
#alias be="bundle_wrapper"


#alias pry-remote="bundle_wrapper pry-remote"
#alias pry="bundle_wrapper pry"

export SPEC_OPTS=--color

export PATH=~/.rbenv/shims:$PATH
export PATH=./bin:$PATH

# source /usr/local/opt/chruby/share/chruby/chruby.sh
# source /usr/local/opt/chruby/share/chruby/auto.sh

# function chruby_install() {
#   ruby-build $1 /opt/rubies/$1
# }

# export RUBIES=(
#   ~/.rbenv/versions/*
# )
