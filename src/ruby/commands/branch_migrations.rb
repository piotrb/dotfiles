module Commands
  module BranchMigrations
    extend CommandHelpers

    class << self
      def init
        require_relative "../lib/git"
      end

      def run(args)
        command = args.shift

        case command
        when "list"
          puts "Migrations in this branch:"
          list.sort.each do |file|
            puts " - #{file}"
          end
        when "undo"
          puts "Undoing migrations in this branch ..."
          list.sort.reverse_each do |file|
            version = File.basename(file)[/^\d+/]
            run_shell "bundle exec rake db:migrate:down VERSION=#{version}"
          end
        else
          warn "unknown command: #{command.inspect}"
          warn "  valid commands: list, undo"
          exit 1
        end
      end

      def list
        base_branch = Git.branch_exists?("develop") ? "develop" : "master"
        `git log --name-only --pretty="format:" #{base_branch}..HEAD db/migrate`.split("\n").map(&:strip).reject(&:empty?).uniq
      end
    end
  end
end
