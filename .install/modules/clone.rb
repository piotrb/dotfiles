# frozen_string_literal: true

require_relative './_common'

module CloneModule
  include CommonModule

  def evaluate(repo, path, update: false)
    with_plan do |plan|
      path = File.expand_path(path)
      if File.exist?(path)
        if update
          head_revision = `cd #{path.inspect} && git rev-parse HEAD`.strip
          current_branch = `cd #{path.inspect} && git rev-parse --abbrev-ref HEAD`.strip
          remote_head = `cd #{path.inspect} && git ls-remote origin #{current_branch}`.split("\t").first
          if head_revision != remote_head
            notes = []
            notes << "HEAD: #{head_revision}"
            notes << "REMOTE HEAD: #{remote_head}"
            sh("cd #{path.inspect} && git fetch -q ")
            commits = `cd #{path.inspect} && git log #{head_revision}..#{remote_head} --oneline`.strip.split("\n")
            notes << "Commits: (#{commits.length})"
            notes += commits.map { |c| "  #{c}" }
            plan << [:clone, repo, path, { mode: :update, remote_head: remote_head }, { notes: notes.join("\n") }]
          end
        end
      else
        plan << [:clone, repo, path]
      end
    end
  end

  def run(repo, path, mode: :new, remote_head: nil)
    case mode
    when :update
      sh("cd #{path.inspect} && git reset --hard #{remote_head.inspect}")
    when :new
      sh("git clone --recursive #{repo.inspect} #{path.inspect}")
    else
      raise "unknown mode: #{mode}"
    end
  end
end

ModuleRegistry.register_module :clone, CloneModule
