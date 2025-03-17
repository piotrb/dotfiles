# frozen_string_literal: true

require_relative './_common'

module GoGetModule
  include CommonModule

  module Actions
    def get(package, **kwargs)
      sh("go get #{package.inspect}")
    end
  end

  def evaluate(package)
    with_plan do |plan|
      plan << action(:get, package)
    end
  end
end

ModuleRegistry.register_module :go_get, GoGetModule
