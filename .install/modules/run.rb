# frozen_string_literal: true

require_relative './_common'

module RunModule
  include CommonModule

  def evaluate(cmd)
    with_plan do |plan|
      plan << [:run, cmd]
    end
  end

  def run(cmd)
    sh(cmd)
  end
end

ModuleRegistry.register_module :run, RunModule
