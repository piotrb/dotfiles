# frozen_string_literal: true

require_relative './_common'

class AptfileDSL < BasicObject
  attr_reader :entries

  def self.read(aptfile)
    interface = new
    interface.instance_eval(::File.read(aptfile), aptfile)
    interface.entries
  end

  def initialize
    @entries = []
  end

  def deb(package)
    entries << [:deb, package]
  end
end

class AptPlanner
  def initialize(aptfile)
    @entries = AptfileDSL.read(aptfile)
  end

  def supported?
    `which apt-get 2>/dev/null`.strip != ''
  end

  def plan
    return [] unless supported?

    installed = installed_packages
    result = []
    @entries.each do |type, package|
      case type
      when :deb
        result << [type, package] unless installed.include?(package)
      else
        raise ArgumentError, "unhandled entry: #{[type, package].inspect}"
      end
    end
    result
  end

  private

  def installed_packages
    @installed_packages ||= `dpkg-query -W -f='${Package}\n' 2>/dev/null`.lines.map(&:strip)
  end
end

module AptModule
  include CommonModule

  module Actions
    module ActionProxy
      def format_plan_item(item)
        case item[0]
        when :deb
          "Deb: #{item[1].inspect}"
        else
          item.inspect
        end
      end

      def format_args_for_print
        result = String.new
        apt_plan = @args[0]
        result << "\n" unless apt_plan.empty?
        apt_plan.each do |item|
          result << '  ' << format_plan_item(item) << "\n"
        end
        result
      end
    end

    def apply_plan(apt_plan, **kwargs)
      unless kwargs.keys.empty?
        raise ArgumentError, "unhandled kwargs: #{kwargs.inspect}"
      end

      return if apt_plan.empty?

      sh('sudo apt-get update')
      apt_plan.each do |component, *args|
        case component
        when :deb
          package, = args
          sh("sudo apt-get install -y #{package.inspect}")
        else
          raise ArgumentError, "unhandled component: #{component.inspect}"
        end
      end
    end
  end

  def evaluate(aptfile)
    apt_plan = AptPlanner.new(aptfile).plan
    with_plan do |plan|
      plan << action(:apply_plan, apt_plan) unless apt_plan.empty?
    end
  end
end

ModuleRegistry.register_module :apt, AptModule
