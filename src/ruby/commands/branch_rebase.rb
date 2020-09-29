module Commands
  module BranchRebase
    extend CommandHelpers

    class << self
      def init
        require "optparse"
        require_relative "../lib/git"
      end

      def run(args)
        dispatch_valid_commands(args)
      end

      def cmd_list(args)
        bases = bases_from_config
        ap bases
      end

      def cmd_add(args)
        bases = bases_from_config
        bases |= args
        save_bases_to_config(bases)
      end

      def cmd_remove(args)
        bases = bases_from_config
        bases.reject! { |n| args.include?(n) }
        save_bases_to_config(bases)
      end

      def cmd_rebase(args)
        options = {}
        OptionParser.new { |opts|
          opts.on("-i", "Interactive") do |v|
            options[:interactive] = v
          end
        }.parse!(args)

        fail("git is dirty") if Git.dirty?
        tmp_branch = "tmp-base/#{branch_name}"

        Git.fetch("origin", quiet: true)

        begin
          if Git.branch_exists?(tmp_branch)
            Git.delete_branch(tmp_branch, force: true)
          end
          Git.checkout(to_branch: tmp_branch)

          Git.reset("origin/develop", hard: true)
          bases = bases_from_config
          bases.each do |base|
            Git.merge("origin/#{base}", ff: false, edit: false)
          end
        ensure
          Git.checkout(branch_name)
        end

        status = Git.rebase(tmp_branch, return_status: true, interactive: options[:interactive])
        if status != 0
          warn "Rebase failed!"
          warn "Follow the regular rebase process to finish it up"
        else
          Git.delete_branch(tmp_branch, force: true)
        end
      end

      private

      def save_bases_to_config(new_bases)
        Git.set_config("branch.#{branch_name}.base-branches", new_bases.join(","))
      end

      def bases_from_config
        Git.get_config("branch.#{branch_name}.base-branches").split(",")
      end

      def branch_name
        @branch_name ||= Git.current_branch
      end
    end
  end
end
