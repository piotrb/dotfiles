# frozen_string_literal: true

require 'singleton'

class ModuleRegistry
  include Singleton

  attr_reader :modules

  def initialize
    @modules = {}
  end

  def self.register_module(name, mod)
    proxy_object = ::Object.new.tap { |o| o.extend mod }
    proxy_object.define_singleton_method(:inspect) { "<ModuleProxy: #{name}>" }

    actions_module = mod::Actions

    actions = {}

    actions_module.instance_methods(false).each do |method|
      actions[method] = actions_module.instance_method(method).bind(proxy_object)
    end

    proxy_object.define_singleton_method(:actions_module) { actions_module }

    proxy_object.define_singleton_method(:mod_name) do
      mod.name.gsub(/Module$/, '')
    end

    proxy_object.define_singleton_method(:actions) do
      actions
    end

    instance.modules[name] = proxy_object
  end

  def plan_context(base_class)
    instance = base_class.new
    modules.each do |name, mod|
      instance.define_singleton_method(name) do |*args, **kargs|
        r = mod.evaluate(*args, **kargs)
        @plan += r if r
      end
    end
    instance
  end
end

class PlanContext
  attr_reader :plan

  def initialize
    @plan = []
  end
end

class PlanMaker
  attr_reader :plan

  def self.plan(&block)
    puts 'Preparing plan ...'

    interface = PlanMaker.new
    interface.exec(&block)

    if interface.empty?
      puts 'Plan is empty. Nothing to do.'
      return
    end

    interface.print

    unless ENV['NON_INTERACTIVE']
      puts 'Are you sure you want to apply these changes? (only "yes" will be accepted)'

      input = gets.strip

      if input != 'yes'
        warn 'Aborting!'
        return
      end
    end

    interface.run
  end

  def exec(&block)
    context = ModuleRegistry.instance.plan_context(PlanContext)
    context.instance_exec(&block)
    @plan = context.plan
  end

  def run
    plan.each(&:call)
  end

  def empty?
    plan.empty?
  end

  def print
    max_module = plan.map { |line| line.mod_name.length }.max
    plan.each do |proxy|
      prefix = format('%*s: ', max_module, proxy.mod_name)
      output = proxy.format_for_print
      puts prefix_first_line(prefix, output)
    end
  end

  def prefix_first_line(prefix, lines)
    lines.split("\n").each_with_index.map do |line, index|
      if index.zero?
        prefix + line
      else
        prefix.gsub(/./, ' ') + line
      end
    end.join("\n")
  end
end
