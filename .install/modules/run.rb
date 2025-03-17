# frozen_string_literal: true

require_relative './_common'

module RunModule
  include CommonModule

  module Actions
    def run(cmd, state: nil, state_globs: nil, **kwargs)
      sh(cmd)
      state_update(state, state_globs) if state && state_globs
    end
  end

  def evaluate(cmd, state: nil, state_globs: nil)
    with_plan do |plan|
      if state && state_globs
        plan << action(:run, cmd, state: state, state_globs: state_globs) unless state_check(state, state_globs)
      else
        plan << action(:run, cmd)
      end
    end
  end
end

ModuleRegistry.register_module :run, RunModule
