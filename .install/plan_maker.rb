# frozen_string_literal: true

require 'singleton'

class ModuleRegistry
  include Singleton

  attr_reader :modules

  def initialize
    @modules = {}
  end

  def self.register_module(name, mod)
    instance.modules[name] = ::Object.new.tap { |o| o.extend mod }
  end

  def plan_context(base_class)
    instance = base_class.new
    modules.each do |name, mod|
      instance.define_singleton_method(name) do |*args|
        r = mod.evaluate(*args)
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

    interface.print

#     puts 'Are you sure you want to apply these changes? (only "yes" will be accepted)'

#     input = gets.strip

#     if input != 'yes'
#       warn 'Aborting!'
#       return
#     end

    interface.run
  end

  def exec(&block)
    context = ModuleRegistry.instance.plan_context(PlanContext)
    context.instance_exec(&block)
    @plan = context.plan
  end

  def run
    plan.each do |module_name, *args|
      mod = ModuleRegistry.instance.modules[module_name]
      mod.run(*args)
    end
  end

  def print
    max_module = plan.map { |line| line[0].to_s.length }.max
    plan.each do |module_name, *args|
      prefix = format('%*s: ', max_module, module_name)
      mod = ModuleRegistry.instance.modules[module_name]
      output = mod.format_for_print(*args)
      puts prefix_first_line(prefix, output)
    end
  end

  def respond_to_missing?(method_name)
    ::ModuleRegistry.instance.respond_to?(method_name)
  end

  def method_missing(method_name, *args)
    ::ModuleRegistry.instance.send(method_name, *args)
  end

  def prefix_first_line(prefix, lines)
    lines.split("\n").each_with_index.map do |line, index|
      if index == 0
        prefix + line
      else
        prefix.gsub(/./, ' ') + line
      end
    end.join("\n")
  end
end
