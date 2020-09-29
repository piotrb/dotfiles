# frozen_string_literal: true

require_relative './_common'

module GitConfigModule
  include CommonModule

  def evaluate(config_hash)
    with_plan do |plan|
      missing = []
      current_config = Kernel.send('`', 'git config --global -l').strip.split("\n").map { |l| l.split('=', 2) }.to_h
      flat_hash(config_hash).each do |k, v|
        key = k.map(&:to_s).join('.').downcase
        missing << [key, v.to_s] if current_config[key] != v.to_s
      end

      plan << [:git_config, missing] unless missing.empty?
    end
  end

  def run(values)
    values.each do |key, value|
      sh "git config --global #{key} #{value.to_s.inspect}"
    end
  end

  private

  def flat_hash(hash, k = [])
    return { k => hash } unless hash.is_a?(Hash)

    hash.inject({}) { |h, v| h.merge! flat_hash(v[-1], k + [v[0]]) }
  end
end

ModuleRegistry.register_module :git_config, GitConfigModule
