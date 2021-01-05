include CommandHelpers

def init
  require "yaml/store"
  require_relative "../../lib/cri_command_support"
  extend CriCommandSupport

  require "action_view"
  extend ::ActionView::Helpers::DateHelper
end

def run(args)
  root_cmd = build_root_cmd

  root_cmd.run(args, {}, hard_exit: false)
end

private

def config
  @config ||= YAML::Store.new(File.expand_path("~/.brewx.yml"))
end

def brew_leaves
  `brew leaves`.split("\n").map(&:strip)
end

def requested_cmd
  cmd = define_cmd("requested") { |_opts, _args, cmd|
    cmd.run(["list"])
  }

  list_cmd = define_cmd("list") {
    config.transaction(true) do
      puts "Requested packages:"
      config.fetch(:requested, []).each do |pkg|
        puts "- #{pkg}"
      end
    end
  }

  add_cmd = define_cmd("add") { |_opts, args, _cmd|
    config.transaction do
      config[:requested] ||= []
      config[:requested] |= args
      config[:requested].sort!

      puts "Requested packages:"
      config.fetch(:requested, []).each do |pkg|
        puts "- #{pkg}"
      end
    end
  }

  rm_cmd = define_cmd("rm") { |_opts, args, _cmd|
    config.transaction do
      config[:requested] ||= []
      config[:requested] -= args
      config[:requested].sort!

      puts "Requested packages:"
      config.fetch(:requested, []).each do |pkg|
        puts "- #{pkg}"
      end
    end
  }

  cmd.add_command(list_cmd)
  cmd.add_command(add_cmd)
  cmd.add_command(rm_cmd)

  cmd
end

def orphans_cmd
  define_cmd("orphans") do
    requested = config.transaction(true) { config.fetch(:requested, []) }
    orphans = brew_leaves - requested
    p orphans
  end
end

def uninstall_cmd
  define_cmd("uninstall", summary: "Uninstall a package, listing any new leaves created") do |_opts, args, _cmd|
    leaves = brew_leaves
    p leaves
    p args
    system ["brew uninstall", args].join(" ")
    after_leaves = brew_leaves
    new_leaves = after_leaves - leaves
    p new_leaves
  end
end

def update_interactive_cmd
  define_cmd("update_interactive") do
    prompt = TTY::Prompt.new

    list = JSON.parse(`brew outdated --json`)

    result = prompt.multi_select("Update packages?", per_page: 99) { |menu|
      list["formulae"].each do |item|
        label = [
          "#{item["name"]} (#{item["installed_versions"].join(", ")} -> #{item["current_version"]})",
          item["pinned"] ? "[pinned: #{item["pinned_version"]}]" : nil
        ].compact.join(" ")

        menu.choice label, item["name"], disabled: item["pinned"]
      end
    }

    if result.length > 0
      system "brew upgrade #{result.join(" ")}"
    else
      puts "nothing selected!"
    end
  rescue TTY::Reader::InputInterrupt
    puts "Aborted!"
  end
end

def build_root_cmd
  root_cmd = define_cmd("brewx", summary: "Brew Extensions", help: true)

  root_cmd.add_command(uninstall_cmd)
  root_cmd.add_command(requested_cmd)
  root_cmd.add_command(orphans_cmd)
  root_cmd.add_command(update_interactive_cmd)

  x_cmd = define_cmd("x") { |_|
    result = []

    info = JSON.parse(`brew info --json --installed`)
    info.each do |item|
      item["installed"].each do |i|
        receipt = "/usr/local/Cellar/#{item["name"]}/#{i["version"]}/INSTALL_RECEIPT.json"
        receipt_info = JSON.parse(File.read(receipt))
        result << [
          item["name"],
          i["version"],
          Time.at(receipt_info["time"])
        ]
      end
    end

    result.sort_by! { |row| row[2] }
    result.map! { |row| [row[0], row[1], distance_of_time_in_words_to_now(row[2])] }

    table = TTY::Table.new(header: ["Package", "Version", "Installed"], rows: result)
    puts table.renderer(:unicode, padding: [0, 1, 0, 1]).render
  }

  root_cmd.add_command(x_cmd)
end
