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

  def args_for_run(args)
    if args[-1].is_a?(Hash) && args[-1].keys == [:notes]
      args_for_run(args[0..-2])
    else
      if args[-1].is_a?(Hash)
        [args[0..-2], args[-1]]
      else
        [args, {}]
      end
    end
  end

  def format_for_print(*args)
    if args.length == 1
      args[0].inspect
    else
      if args[-1].is_a?(Hash) && args[-1].keys == [:notes]
        notes = args[-1][:notes].split("\n").map { |l| (' ' * 2) + l }.join("\n")
        args[0..-2].inspect + "\n# Notes:\n#{notes}"
      else
        args.inspect
      end
    end
  end

  def state_checksums(state_globs)
    matching_files = state_globs.flat_map { |glob| Dir.glob(File.expand_path(glob)) }.sort.uniq.select { |fn| File.file?(fn) }
    checksums = matching_files.map { |fn| [fn, Digest::SHA256.file(fn).hexdigest] }.to_h
    checksums.to_yaml
  end

  def state_update(state_file, state_globs)
    FileUtils.mkdir_p(File.expand_path("~/.config/dotfiles"))
    state_filename = File.expand_path("~/.config/dotfiles/#{state_file}")
    checksums = state_checksums(state_globs)
    File.write(state_filename, checksums)
  end

  # return true if the state file exists and matches the checksums
  def state_check(state_file, state_globs)
    FileUtils.mkdir_p(File.expand_path("~/.config/dotfiles"))
    state_filename = File.expand_path("~/.config/dotfiles/#{state_file}")
    checksums = state_checksums(state_globs)
    if File.exist?(state_filename)
      if File.read(state_filename) == checksums
        # matching
        true
      else
        false
      end
    else
      false
    end
  end
end
