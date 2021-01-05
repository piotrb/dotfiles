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

def camelize(string)
  string.split("_").map(&:capitalize).join
end

def load_command(into:, name:, path:)
  runner_class = Class.new
  into.const_set(camelize(name.to_s), runner_class)
  runner_class.class_eval(File.read(path), path, 1)
  runner_class
end

def run_command_file(path:, name:, args:, load_into:)
  runner_class = load_command(into: load_into, name: name, path: path)
  runner = runner_class.new
  runner.init if runner.respond_to?(:init)
  runner.run(args)
end

def execute_command(name, args)
  load_gemfile(File.expand_path("commands/#{name}/Gemfile", __dir__))

  require_relative "lib/command_helpers"

  # just in case we don't have it in the gem
  gem "activesupport"
  require "active_support/all"

  v2_path = File.expand_path("commands/#{name}/main.rb", __dir__)
  run_command_file(path: v2_path, name: name, args: args, load_into: Commands)
end
