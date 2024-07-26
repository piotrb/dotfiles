# frozen_string_literal: true

require_relative './_common'

class BrewPlanner
  attr_reader :entries, :requested

  BREWX_CONFIG = File.expand_path('~/.brewx.yml')

  def initialize(brewfile)
    @entries = BrewfileDSL.read(brewfile)
    @requested = []
  end

  def supported?
    `which brew 2>/dev/null`.strip != ''
  end

  def plan
    return [] unless supported?

    result = []
    entries.each do |type, *args|
      case type
      when :tap
        result << [type, *args] unless tap_installed?(args[0])
      when :brew
        result << [type, *args] unless brew_package_installed?(args[0])
        requested << args[0]
      when :cask
        result << [type, *args] unless cask_installed?(args[0])
      else
        raise ArgumentError, "unhandled entry: #{[type, *args].inspect}"
      end
    end

    result += requested_diff

    result
  end

  private

  def requested_diff
    current_requested = if File.exist?(BREWX_CONFIG)
                          YAML.load_file(BREWX_CONFIG)[:requested] || []
                        else
                          []
                        end
    missing = requested - current_requested
    extra = current_requested - requested

    return [] if missing.empty? && extra.empty?

    params = {}
    params[:add] = missing unless missing.empty?
    params[:remove] = extra unless extra.empty?

    [[:manage_requested, params]]
  end

  def all_taps
    @all_taps ||= `HOMEBREW_NO_AUTO_UPDATE=1 brew tap`.strip.split("\n")
  end

  def all_packages
    @all_packages ||= `HOMEBREW_NO_AUTO_UPDATE=1 brew list --full-name --formulae`.strip.split("\n")
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

  def brew(package, args: nil, start_service: nil, link: nil)
    entries << [:brew, package, {
      args:,
      start_service:,
      link:
    }.compact,]
  end

  def cask(package)
    entries << [:cask, package]
  end
end

module BrewModule
  include CommonModule

  module Actions
    module ActionProxy
      def format_plan_item(item)
        case item[0]
        when :manage_requested
          "Manage Requested: #{item[1].inspect}"
        when :tap
          "Tap: #{item[1].inspect}"
        when :brew
          "Brew: #{item[1].inspect}"
        when :cask
          "Cask: #{item[1].inspect}"
        else
          item.inspect
        end
      end

      def format_args_for_print
        result = String.new
        brew_plan = @args[0]
        result << "\n" unless brew_plan.empty?
        brew_plan.each do |item|
          result << '  ' << format_plan_item(item) << "\n"
        end
        result
      end
    end

    def apply_plan(brew_plan)
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
          sh("brew services start #{package.inspect}") if options[:start_service]
        when :cask
          package, = args
          sh("brew install --cask #{package.inspect}")
        when :manage_requested
          opts, = args
          data = if File.exist?(BrewPlanner::BREWX_CONFIG)
                   YAML.load_file(BrewPlanner::BREWX_CONFIG)
                 else
                   {}
                 end
          data[:requested] ||= []
          data[:requested] += opts[:add] if opts[:add]
          data[:requested] -= opts[:remove] if opts[:remove]
          File.open(BrewPlanner::BREWX_CONFIG, 'w') { |f| f.write(YAML.dump(data)) }
        else
          raise ArgumentError, "unhandled component: #{component.inspect}"
        end
      end
    end
  end

  def evaluate(brewfile)
    brew_plan = BrewPlanner.new(brewfile).plan
    with_plan do |plan|
      # plan << [:brew, brew_plan] unless brew_plan.empty?
      plan << action(:apply_plan, brew_plan) unless brew_plan.empty?
    end
  end
end

ModuleRegistry.register_module :brew, BrewModule
