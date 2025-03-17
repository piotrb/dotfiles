# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module ShellModule
  include CommonModule

  module Actions
    def chsh(new_shell, **kwargs)
      sh "sudo chsh -s #{new_shell} `whoami`"
    end
  end

  def evaluate(new_shell)
    with_plan do |plan|
      plan << action(:chsh, new_shell) if ENV['SHELL'] != new_shell
    end
  end
end

ModuleRegistry.register_module :shell, ShellModule
