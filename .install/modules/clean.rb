# frozen_string_literal: true

require_relative './_common'

module CleanModule
  include CommonModule

  def evaluate(path)
    with_plan do |plan|
      path = File.expand_path(path)
      Dir["#{path}/*", "#{path}/.*"].each do |fn|
        next unless File.symlink?(fn)

        begin
          File.realpath(fn)
        rescue Errno::ENOENT
          plan << [:clean, :unlink, fn]
        end
      end
    end
  end

  def run(action, path)
    case action
    when :unlink
      original = File.readlink(path)
      puts "clean: #{path} (originally: #{original})"
      File.unlink(path)
    else
      raise ArgumentError, "unhandled action: #{action.inspect}"
    end
  end
end

ModuleRegistry.register_module :clean, CleanModule
