# frozen_string_literal: true

require 'fileutils'

require_relative './_common'

module LinkModule
  include CommonModule

  module Actions
    def mkdir_p(dst, **kwargs)
      puts "mkdir_p: #{dst}"
      FileUtils.mkdir_p(dst)
    end

    def rm_rf(dst, **kwargs)
      puts "rm_rf: #{dst}"
      FileUtils.rm_rf(dst)
    end

    def ln_s(src, dst, **kwargs)
      puts "ln: #{src} -> #{dst}"
      FileUtils.ln_s(src, dst)
    end

    def unlink(dst, **kwargs)
      puts "unlink: #{dst}"
      File.unlink(dst)
    end
  end

  def evaluate(dst, from:)
    with_plan do |plan|
      dst = File.expand_path(dst)
      src = File.expand_path(from)
      need_symlink = true
      if File.exist?(dst)
        need_symlink = false
        if File.symlink?(dst)
          unless File.readlink(dst) == src
            plan << action(:unlink, dst)
            need_symlink = true
          end
        else
          if File.directory?(dst)
            plan << action(:rm_rf, dst)
          else
            plan << action(:unlink, dst)
          end
          need_symlink = true
        end
      end
      plan << action(:mkdir_p, File.dirname(dst)) unless File.exist?(File.dirname(dst))
      plan << action(:ln_s, src, dst) if need_symlink
    end
  end
end

ModuleRegistry.register_module :link, LinkModule
