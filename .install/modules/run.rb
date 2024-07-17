# frozen_string_literal: true

require_relative './_common'

module RunModule
  include CommonModule

  def evaluate(cmd, state: nil, state_globs: nil)
    with_plan do |plan|
      if state && state_globs
        unless state_check(state, state_globs)
          plan << [:run, cmd, { state: state, state_globs: state_globs }]
        end
      else
        plan << [:run, cmd, {}]
      end
    end
  end

  def run(cmd, state: nil, state_globs: nil)
    sh(cmd)
    if state && state_globs
      state_update(state, state_globs)
    end
  end
end

ModuleRegistry.register_module :run, RunModule
