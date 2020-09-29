# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module DirModule
  include CommonModule

  def evaluate(path)
    with_plan do |plan|
      path = File.expand_path(path)
      plan << [:dir, path] unless File.exist?(path)
    end
  end

  def run(path)
    puts "mkdir: #{path}"
    FileUtils.mkdir_p(path)
  end
end

ModuleRegistry.register_module :dir, DirModule
