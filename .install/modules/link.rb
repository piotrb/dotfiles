# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module LinkModule
  include CommonModule

  def evaluate(dst, from:)
    with_plan do |plan|
      dst = File.expand_path(dst)
      src = File.expand_path(from)
      if File.exist?(dst)
        if File.symlink?(dst)
          plan << [:link, :unlink, dst] unless File.readlink(dst) == src
        else
          plan << [:link, :unlink, dst]
        end
      end
      plan << [:link, :mkdir_p, File.dirname(dst)] unless File.exist?(File.dirname(dst))
      plan << [:link, :ln_s, src, dst] unless File.exist?(dst)
    end
  end

  def run(action, src, dst = nil)
    case action
    when :unlink
      puts "unlink: #{src}"
      File.unlink(src)
    when :ln_s
      puts "ln: #{src} -> #{dst}"
      FileUtils.ln_s(src, dst)
    when :mkdir_p
      puts "mkdir_p: #{src}"
      FileUtils.mkdir_p(src)
    else
      raise ArgumentError, "unhandled action: #{action.inspect}"
    end
  end
end

ModuleRegistry.register_module :link, LinkModule
