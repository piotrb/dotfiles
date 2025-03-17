# frozen_string_literal: true

require_relative './_common'

module AsdfPluginModule
  include CommonModule

  module Actions
    def install(name, after_install: nil)
      sh("asdf plugin add #{name}")
      return unless after_install

      puts 'Running after_install commands ...'
      after_install.each do |line|
        sh(line)
      end
    end
  end
  
  def supported?
    `which asdf 2>/dev/null`.strip != ''
  end

  def evaluate(name, after_install: nil)
    with_plan do |plan|
      if supported?
        installed_plugins = `asdf plugin list`.strip.split("\n")
        plan << action(:install, name, after_install: after_install) unless installed_plugins.include?(name)
      end
    end
  end
end

ModuleRegistry.register_module :asdf_plugin, AsdfPluginModule
