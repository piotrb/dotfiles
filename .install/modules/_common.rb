# frozen_string_literal: true

require 'English'
require 'yaml'
require 'digest'

module CommonModule
  def with_plan
    plan = []
    yield plan
    plan
  end

  def sh(cmd)
    puts "$: #{cmd}"
    system(cmd) || raise("command failed with status: #{$CHILD_STATUS.exitstatus}")
  end

  def state_checksums(state_globs)
    matching_files = state_globs.flat_map { |glob| Dir.glob(File.expand_path(glob)) }.sort.uniq.select { |fn| File.file?(fn) } # rubocop:disable Layout/LineLength
    checksums = matching_files.map { |fn| [fn, Digest::SHA256.file(fn).hexdigest] }.to_h
    checksums.to_yaml
  end

  def state_update(state_file, state_globs)
    FileUtils.mkdir_p(File.expand_path('~/.config/dotfiles'))
    state_filename = File.expand_path("~/.config/dotfiles/#{state_file}")
    checksums = state_checksums(state_globs)
    File.write(state_filename, checksums)
  end

  # return true if the state file exists and matches the checksums
  def state_check(state_file, state_globs)
    FileUtils.mkdir_p(File.expand_path('~/.config/dotfiles'))
    state_filename = File.expand_path("~/.config/dotfiles/#{state_file}")
    checksums = state_checksums(state_globs)
    if File.exist?(state_filename)
      File.read(state_filename) == checksums
    else
      false
    end
  end

  def action(name, *args, __notes: nil, **kwargs)
    proxy = ActionProxy.new(mod_name, name, args, kwargs, actions[name], notes: __notes)
    proxy.extend(actions_module::ActionProxy) if Module.const_defined?("#{actions_module}::ActionProxy")
    proxy
  end

  # def self.included(other)
  #   other.extend(ClassMethods)
  # end
end

class ActionProxy
  def initialize(mod_name, action_name, args, kwargs, action_block, notes: nil)
    @mod_name = mod_name
    @action_name = action_name
    @args = args
    @kwargs = kwargs
    @action_block = action_block
    @notes = notes
  end

  attr_reader :mod_name

  def format_for_print
    result = String.new
    result << "#{@action_name}("
    result << format_args_for_print
    result << ')'
    if @notes
      result << "\n"
      result << @notes
      result << "\n"
    end
    result
  end

  def format_args_for_print
    result = String.new
    result << @args.map(&:inspect).join(', ') if @args.length.positive?
    if @kwargs.length.positive?
      result << ', ' if @args.length.positive?
      result << @kwargs.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
    end
    result
  end

  def call
    @action_block.call(*@args, **@kwargs)
  end

  def inspect
    "<ActionProxy: Module: #{@module_name}, Action: #{@action_name}, Args: #{@args}, Kwargs: #{@kwargs}>"
  end
end
