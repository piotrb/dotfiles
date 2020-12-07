# frozen_string_literal: true

require 'English'

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

  def format_for_print(*args)
    if args.length == 1
      args[0].inspect
    else
      args.inspect
    end
  end
end
