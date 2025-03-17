# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module DirModule
  include CommonModule

  module Actions
    def mkdir(path, **kwargs)
      puts "mkdir: #{path}"
      FileUtils.mkdir_p(path)
    end
  end

  def evaluate(path)
    with_plan do |plan|
      path = File.expand_path(path)
      plan << action(:mkdir, path) unless File.exist?(path)
    end
  end
end

ModuleRegistry.register_module :dir, DirModule
