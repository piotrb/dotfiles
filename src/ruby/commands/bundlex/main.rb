def init
  require_relative "../../lib/cri_command_support"
  extend CriCommandSupport
end

def run(args)
  root_cmd = build_root_cmd
  root_cmd.run(args, {}, hard_exit: false)
end

def build_root_cmd
  root_cmd = define_cmd("bundlex", summary: "Bundle Extensions", help: true)

  root_cmd.add_command(outdated_cmd)
end

def outdated_cmd
  define_cmd("outdated") do
    require_relative "./outdated"
    OutdatedCmd.init
    OutdatedCmd.run([])
  end
end
