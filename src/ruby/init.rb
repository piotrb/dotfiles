# frozen_string_literal: true

require "English"
require "yaml"

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

def load_deps(name)
  fn = File.expand_path("deps/#{name}.gemfile", __dir__)
  if File.exist?(fn)
    env_undo do
      ENV["BUNDLE_GEMFILE"] = fn
      # ENV['BUNDLE_PATH'] = File.expand_path("deps/bundle", __dir__)
      ENV["GEM_HOME"] = File.expand_path("deps/bundle", __dir__)
      require "bundler"
      begin
        Bundler.require(:default)
        Bundler.reset_paths!
        Bundler.clear_gemspec_cache
      rescue Bundler::VersionConflict, Bundler::GemNotFound, LoadError => e
        puts "#{e.class}: #{e.message}"
        print "Would you like to run bundle install? (only `yes' will be accepted) => "
        input = gets.strip
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
  end
end

def execute_command(name, args)
  load_deps(name)

  require_relative "lib/command_helpers"

  # just in case we don't have it in the gem
  gem "activesupport"
  require "active_support/all"

  require_relative "commands/#{name}"
  klass = "Commands::#{name.to_s.camelcase}".constantize
  klass.init if klass.respond_to? :init
  klass.run(args)
end
