# frozen_string_literal: true

require "shellwords"

module CommandHelpers
  def valid_commands
    methods.grep(/^cmd_/).map { |method| method.to_s.gsub(/^cmd_/, "") }
  end

  def dispatch_valid_commands(args)
    args = args.dup
    command = args.shift

    if valid_commands.include?(command)
      public_send("cmd_#{command}", args)
    else
      fail("unknown command: #{command.inspect}",
        "  valid commands: #{valid_commands.inspect}")
    end
  end

  def clean_env(type:, &block)
    backup = {}
    removed_keys = case type
                   when :ruby
                     ENV.keys.grep(/^(?:RBENV_|RUBYLIB)/)
                   else
                     raise ArgumentError, "unsupported type: #{type}"
    end

    removed_keys.each do |k|
      backup[k] = ENV[k]
    end

    removed_keys.each do |k|
      ENV.delete k
    end

    block.call
  ensure
    backup.each do |k, v|
      ENV[k] = v
    end
  end

  def log(message, depth: 0, newline: true)
    message = Array(message)
    message.each do |m|
      indent = "  " * depth
      print indent + m
      print "\n" if newline
    end
  end

  def join_cmd(args)
    if args.is_a? Array
      Shellwords.join(args)
    else
      args
    end
  end

  def run_with_each_line(command)
    command = join_cmd(command)
    Open3.popen2e(command) { |_stdin, stdout_and_stderr, wait_thr|
      pid = wait_thr.pid # pid of the started process.
      until stdout_and_stderr.eof?
        raw_line = stdout_and_stderr.gets
        yield(raw_line)
      end
      wait_thr.value # Process::Status object returned.
    }
  end

  def run_shell(command, return_status: false, echo_command: true, quiet: false, indent: 0)
    command = join_cmd(command)
    puts "#{" " * indent}$> #{command}" if echo_command
    command += " 1>/dev/null 2>/dev/null" if quiet
    system command.to_s
    code = $CHILD_STATUS.exitstatus
    raise("failed with code: #{code}") if !return_status && code > 0

    code
  end

  def capture_shell(command, error: true, echo_command: true, indent: 0, raise_on_error: false, detailed_result: false)
    command = join_cmd(command)
    puts "#{" " * indent}<< #{command}" if echo_command
    command += " 2>/dev/null" unless error
    value = `#{command}`
    code = $CHILD_STATUS.exitstatus
    raise("capture_shell: #{command.inspect} failed with code: #{code}") if raise_on_error && code > 0
    if detailed_result
      OpenStruct.new({
        status: code,
        output: value,
      })
    else
      value
    end
  end

  def fail(*messages, code: 1)
    messages.each do |message|
      warn(message)
    end
    exit code
  end

  # option_definitions
  # {
  #   name: string
  #   required?: boolean
  #   type?: class
  #   short?: string
  #   long?: string
  #   description?: string
  # }
  # if short and long are blank, name is used as long
  def parse_options(option_definitions, args)
    require "optparse"
    options = {}
    remaining_args = OptionParser.new { |opts|
      option_definitions.each do |od|
        opt_args = [
          od[:required] ? :REQUIRED : nil,
          od[:type],
          od[:short],
          od[:long],
          od[:short].nil? && od[:long].nil? ? od[:name] : nil,
          od[:description],
        ].compact
        opts.on(*opt_args) do |v|
          if od[:multiple]
            options[od[:name]] ||= []
            options[od[:name]] << v
          else
            options[od[:name]] = v
          end
        end
      end
    }.parse!(args)
    [remaining_args, options]
  end
end
