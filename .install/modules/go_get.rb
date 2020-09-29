# frozen_string_literal: true

require_relative './_common'

module GoGetModule
  include CommonModule

  def evaluate(package)
    with_plan do |plan|
      plan << [:go_get, package]
    end
  end

  def run(package)
    sh("go get #{package.inspect}")
  end
end

ModuleRegistry.register_module :go_get, GoGetModule
