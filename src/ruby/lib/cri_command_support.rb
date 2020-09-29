module CriCommandSupport
  def define_cmd(name, summary: nil, help: false, &block)
    cmd_name = name
    Cri::Command.define {
      name cmd_name
      summary summary
      option nil, :help, "show help for this command"
      run do |opts, args, cmd|
        if opts[:help]
          puts cmd.help
        else
          if block
            block.call(opts, args, cmd)
          elsif help
            puts cmd.help
          else
            warn "no action defined for cmd: #{cmd.name}"
          end
        end
      end
    }
  end

  def exit_cmd
    define_cmd("exit") do |opts, args, cmd|
      throw :stop, :exit
    end
  end
end
