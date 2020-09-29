# frozen_string_literal: true

require_relative './_common'

module CloneModule
  include CommonModule

  def evaluate(repo, path)
    with_plan do |plan|
      path = File.expand_path(path)
      plan << [:clone, repo, path] unless File.exist?(path)
    end
  end

  def run(repo, path)
    sh("git clone --recursive #{repo.inspect} #{path.inspect}")
  end
end

ModuleRegistry.register_module :clone, CloneModule
