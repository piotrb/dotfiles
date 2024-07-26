# frozen_string_literal: true

require_relative './_common'

module CleanModule
  include CommonModule

  module Actions
    def unlink(path)
      original = File.readlink(path)
      puts "clean: #{path} (originally: #{original})"
      File.unlink(path)
    end
  end

  def evaluate(path)
    with_plan do |plan|
      path = File.expand_path(path)
      Dir["#{path}/*", "#{path}/.*"].each do |fn|
        next unless File.symlink?(fn)

        begin
          File.realpath(fn)
        rescue Errno::ENOENT
          plan << action(:unlink, fn)
        end
      end
    end
  end
end

ModuleRegistry.register_module :clean, CleanModule
