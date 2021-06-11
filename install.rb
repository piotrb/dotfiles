#!env ruby
# frozen_string_literal: true

require_relative '.install/shared'

plan do
  clean '~'

  brew 'Brewfile'

  # Bin
  dir '~/bin'
  Dir['bin/*'].each do |fn|
    link "~/bin/#{File.basename(fn)}", from: fn
  end

  # Tmux
  link '~/.tmux.conf', from: 'tmux.conf'
  link '~/.tmux.mac.conf', from: 'tmux.mac.conf'

  # Ruby
  link '~/.gemrc', from: 'gemrc'

  # Shared Shell
  link '~/.profile.rc.d', from: 'profile.rc.d'
  link '~/.profile.env.d', from: 'profile.env.d'

  # Bash
  link '~/.bash_profile', from: 'bash_profile'
  link '~/.bashrc', from: 'bashrc'

  # Zsh Configs
  shell '/bin/zsh'
  dir '~/.zsh'
  dir '~/.antigen'
  clone 'https://github.com/zsh-users/antigen.git', '~/.antigen/source'
  link '~/.antigenrc', from: 'antigenrc'
  link '~/.zshrc', from: 'zshrc'
  link '~/.zshenv', from: 'zshenv'

  # vim
  if `which vim 2>/dev/null`.strip != ""
    dir '~/.vim/bundle'
    clone 'https://github.com/gmarik/Vundle.vim.git', '~/.vim/bundle/Vundle.vim'
    link '~/.vim/bundle.vim', from: 'vim/bundle.vim'
    link '~/.vimrc', from: 'vimrc'
    link '~/.gvimrc.after', from: 'gvimrc.after'
    run "vim -u /dev/null -N -c 'source ~/.vim/bundle.vim' +BundleInstall +qall"
  end

  # Git
  link '~/.gitmessage', from: 'gitmessage'
  link '~/.tigrc', from: 'tigrc'
  link '~/.gitignore', from: 'gitignore'

  git_config_hash = {
    gui: {
      gcwarning: false
    },
    pull: {
      rebase: true,
      tags: true
    },
    fetch: {
      prune: true,
      pruneTags: true,
      tags: true
    },
    commit: {
      template: File.expand_path('~/.gitmessage')
    },
    core: {
      mergeoptions: '--no-edit',
      excludesfile: File.expand_path('~/.gitignore'),
      pager: 'less -FX'
    },
    push: {
      default: 'current',
      followTags: true
    },
    status: {
      showUntrackedFiles: 'all'
    },
    diff: {
      compactionHeuristic: 1
    },
    # pager: {
    #   log: 'diff-highlight | less -FX',
    #   show: 'diff-highlight | less -FX',
    #   diff: 'diff-highlight | less -FX'
    # },
    alias: {
      lg: "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)%Creset' --abbrev-commit",
      pf: 'push --force-with-lease'
    },
    rebase: {
      instructionFormat: '[%an] - %s'
    }
  }

  git_config git_config_hash

  # Shell
  dir '~/.config'
  link '~/.config/starship.toml', from: 'config/starship.toml'

  # Go
  go_get 'github.com/piotrb/bundle_wrapper'
  go_get 'github.com/piotrb/git-branchify'
  go_get 'github.com/piotrb/git-prune-merged'
  go_get 'github.com/piotrb/spring_wrapper'
end
