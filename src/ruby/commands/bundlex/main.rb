def init
  require_relative "../../lib/cri_command_support"
  require "yaml"
  extend CriCommandSupport
end

def run(args)
  root_cmd = build_root_cmd
  root_cmd.run(args, {}, hard_exit: false)
end

def build_root_cmd
  root_cmd = define_cmd("bundlex", summary: "Bundle Extensions", help: true)

  root_cmd.add_command(define_file_cmd("outdated", dir: __dir__))
end
