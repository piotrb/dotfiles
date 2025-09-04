#!env ruby
# frozen_string_literal: true

require_relative '.install/shared'

plan do
  clean '~'

  if_exe 'brew' do
    brew 'Brewfile'
  end

  # Bin
  dir '~/bin'
  Dir['bin/*'].each do |fn|
    link "~/bin/#{File.basename(fn)}", from: fn
  end

  # Bash
  link '~/.bash_profile', from: 'bash_profile'
  link '~/.bashrc', from: 'bashrc'

  # Zsh Configs
  shell '/bin/zsh'
  dir '~/.zsh'
  clone 'https://github.com/mattmc3/antidote.git', '~/.antidote', update: true
  link '~/.zsh_plugins.txt', from: 'zsh_plugins.txt'
  link '~/.zshrc', from: 'zshrc'
  link '~/.zshenv', from: 'zshenv'

  link '~/.p10k.zsh', from: 'p10k.zsh'

  link '~/.config/atuin/config.toml', from: 'config/atuin/config.toml'
  
  # Shared Shell
  link '~/.profile.rc.d', from: 'profile.rc.d'
  link '~/.profile.env.d', from: 'profile.env.d'

  # Shell
  dir '~/.config'
  link '~/.config/starship.toml', from: 'config/starship.toml'
  link '~/.config/neofetch/config.conf', from: 'config/neofetch/config.conf'

  # Tmux
  link '~/.tmux.conf', from: 'tmux.conf'
  link '~/.tmux.mac.conf', from: 'tmux.mac.conf'

  # Tools
  link '~/.tool-versions', from: '.tool-versions'

  # Ruby
  link '~/.gemrc', from: 'gemrc'
  link '~/.default-gems', from: 'default-gems'

  # vim
  if_exe 'vim' do
    dir '~/.vim/bundle'
    clone 'https://github.com/gmarik/Vundle.vim.git', '~/.vim/bundle/Vundle.vim', update: true
    link '~/.vim/bundle.vim', from: 'vim/bundle.vim'
    link '~/.vimrc', from: 'vimrc'
    link '~/.gvimrc.after', from: 'gvimrc.after'
    run "vim -en -u ~/.vim/bundle.vim -c BundleInstall -c qall",
        state: 'vim-plugins',
        state_globs: ['~/.vim/**/*', '~/.vimrc']
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
      followTags: true,
      autoSetupRemote: true,
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

  unless ENV['SKIP_GIT']
    git_config git_config_hash
  end

  # # Go
  # if_exe "go" do
  #   go_get 'github.com/piotrb/bundle_wrapper'
  #   go_get 'github.com/piotrb/git-branchify'
  #   go_get 'github.com/piotrb/git-prune-merged'
  #   go_get 'github.com/piotrb/spring_wrapper'
  # end
end
