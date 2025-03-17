# frozen_string_literal: true

require_relative './_common'

module GitConfigModule
  include CommonModule

  module Actions
    def config(values, **kwargs)
      values.each do |key, value|
        sh "git config --global #{key} #{value.to_s.inspect}"
      end
    end

    module ActionProxy
      def format_args_for_print_for_config
        result = String.new
        missing = @args[0]
        if missing.length > 0
          result << "missing:\n"
          missing.each do |k,v|
            result << "  #{k.inspect} -> #{v.inspect}\n"
          end
        end
        result
      end
    end 
  end

  def evaluate(config_hash)
    with_plan do |plan|
      missing = []
      current_config = Kernel.send('`', 'git config --global -l').strip.split("\n").map { |l| l.split('=', 2) }.to_h
      flat_hash(config_hash).each do |k, v|
        key = k.map(&:to_s).join('.').downcase
        missing << [key, v.to_s] if current_config[key] != v.to_s
      end

      plan << action(:config, missing) unless missing.empty?
    end
  end

  private

  def flat_hash(hash, k = []) # rubocop:disable Naming/MethodParameterName
    return { k => hash } unless hash.is_a?(Hash)

    hash.inject({}) { |h, v| h.merge! flat_hash(v[-1], k + [v[0]]) }
  end
end

ModuleRegistry.register_module :git_config, GitConfigModule
