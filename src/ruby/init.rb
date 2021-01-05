# frozen_string_literal: true

require "English"
require "yaml"

module Commands
end

def env_undo
  previous_env = ENV.to_hash
  yield
ensure
  new_env = ENV.to_hash
  new_keys = new_env.keys - previous_env.keys
  new_keys.each do |key|
    ENV.delete(key)
  end
  previous_env.each do |k, v|
    ENV[k] = v
  end
end

def load_gemfile(fn)
  if File.exist?(fn)
    env_undo do
      ENV["BUNDLE_GEMFILE"] = fn
      ENV["GEM_HOME"] = File.expand_path(".bundle", __dir__)
      require "bundler"
      begin
        Bundler.require(:default)
        Bundler.reset_paths!
        Bundler.clear_gemspec_cache
      rescue Bundler::VersionConflict, Bundler::GemNotFound, LoadError => e
        puts "#{e.class}: #{e.message}"
        print "Would you like to run bundle install? (only `yes' will be accepted) => "
        input = $stdin.gets.strip
        if input == "yes"
          system "bundle install"
          Bundler.reset_paths!
          Bundler.clear_gemspec_cache
          Bundler.require
        else
          warn "aborted"
          exit 1
        end
      end
    end
    true
  end
end

def load_command_v1(name, args)
  require_relative "commands/#{name}"
  klass = "Commands::#{name.to_s.camelcase}".constantize
  klass.init if klass.respond_to? :init
  klass.run(args)
end

def camelize(string)
  string.split("_").map(&:capitalize).join
end

def load_command_v2(name, args)
  v2_path = File.expand_path("commands/#{name}/main.rb", __dir__)
  runner_class = Class.new
  Commands.const_set(camelize(name.to_s), runner_class)
  runner_class.class_eval(File.read(v2_path), v2_path, 1)
  runner = runner_class.new
  runner.init if runner.respond_to?(:init)
  runner.run(args)
end

def get_cmd_mode(name)
  v2_path = File.expand_path("commands/#{name}/main.rb", __dir__)
  v1_path = File.expand_path("commands/#{name}.rb", __dir__)
  return :v1 if File.exist?(v1_path)
  return :v2 if File.exist?(v2_path)
end

def execute_command(name, args)
  mode = get_cmd_mode(name)

  case mode
  when :v1
    load_gemfile(File.expand_path("deps/#{name}.gemfile", __dir__))
  when :v2
    load_gemfile(File.expand_path("commands/#{name}/Gemfile", __dir__))
  else
    raise "don't know how to get deps for mode: #{mode.inspect}"
  end

  require_relative "lib/command_helpers"

  # just in case we don't have it in the gem
  gem "activesupport"
  require "active_support/all"

  case mode
  when :v1
    load_command_v1(name, args)
  when :v2
    load_command_v2(name, args)
  else
    raise "don't know how to run command mode: #{mode.inspect}"
  end
end
