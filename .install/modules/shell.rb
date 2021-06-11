# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module ShellModule
  include CommonModule

  def evaluate(new_shell)
    with_plan do |plan|
      plan << [:shell, new_shell] if ENV['SHELL'] != new_shell
    end
  end

  def run(new_shell)
    sh "sudo chsh -s #{new_shell} `whoami`"
  end
end

ModuleRegistry.register_module :shell, ShellModule
