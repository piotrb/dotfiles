# frozen_string_literal: true

require_relative './_common'

class BrewPlanner
  attr_reader :entries

  def initialize(brewfile)
    @entries = BrewfileDSL.read(brewfile)
  end

  def plan
    result = []
    entries.each do |type, *args|
      case type
      when :tap
        result << [type, *args] unless tap_installed?(args[0])
      when :brew
        result << [type, *args] unless brew_package_installed?(args[0])
      when :cask
        result << [type, *args] unless cask_installed?(args[0])
      else
        raise ArgumentError, "unhandled entry: #{[type, *args].inspect}"
      end
    end
    result
  end

  private

  def all_taps
    @all_taps ||= `HOMEBREW_NO_AUTO_UPDATE=1 brew tap`.strip.split("\n")
  end

  def all_packages
    @all_brews ||= `HOMEBREW_NO_AUTO_UPDATE=1 brew list --full-name --formulae`.strip.split("\n")
  end

  def all_casks
    @all_casks ||= `HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask`.strip.split("\n")
  end

  def tap_installed?(tap_name)
    all_taps.include?(tap_name)
  end

  def brew_package_installed?(package)
    all_packages.include?(package)
  end

  def cask_installed?(package)
    all_casks.include?(package)
  end
end

class BrewfileDSL < BasicObject
  attr_reader :entries

  def self.read(brewfile)
    interface = new
    interface.instance_eval(::File.read(brewfile), brewfile)
    interface.entries
  end

  def initialize
    @entries = []
  end

  def tap(source)
    entries << [:tap, source]
  end

  def brew(package, args: nil, restart_service: nil, link: nil)
    entries << [:brew, package, {
      args: args,
      restart_service: restart_service,
      link: link
    }.compact]
  end

  def cask(package)
    entries << [:cask, package]
  end
end

module BrewModule
  include CommonModule

  def evaluate(brewfile)
    brew_plan = BrewPlanner.new(brewfile).plan
    with_plan do |plan|
      plan << [:brew, brew_plan] unless brew_plan.empty?
    end
  end

  def run(brew_plan)
    brew_plan.each do |component, *args|
      case component
      when :tap
        source, = args
        sh("brew tap #{source.inspect}")
      when :brew
        package, options = args
        cmd = "brew install #{package.inspect}"
        options[:args]&.each do |arg|
          cmd << " --#{arg}"
        end
        sh(cmd)
      when :cask
        package, = args
        sh("brew install --cask #{package.inspect}")
      else
        raise ArgumentError, "unhandled component: #{component.inspect}"
      end
    end
  end

  def format_for_print(args, *)
    args.map(&:inspect).join("\n")
  end
end

ModuleRegistry.register_module :brew, BrewModule
