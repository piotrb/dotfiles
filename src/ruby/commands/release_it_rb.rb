module Commands
  module ReleaseItRb
    extend CommandHelpers

    class << self
      def init
        require_relative "../lib/git"
      end

      def run(args)
        # runtime step variables
        @last_changelog = nil

        last = proc {
          if ENV["DRY_RUN"]
            raise "dry run!"
          end
        }

        static_steps = [
          {"type" => "show_version", "options" => {"quiet" => true}},
        ]
        static_pre_steps = [
          {"type" => "git:no_dirty", "options" => {"quiet" => true}},
        ]

        last = build_step_stack(config["steps"], last)
        last = build_step_stack(static_steps, last)
        last = build_step_stack(config["pre_steps"], last) if config["pre_steps"]
        last = build_step_stack(static_pre_steps, last)

        begin
          last.call
        rescue TTY::Reader::InputInterrupt
          warn "Interrupted"
        rescue SystemExit
          # calling abort already prints this .. so just doing nothing
        rescue Exception => e
          warn "#{e.class}: #{e.message}"
          warn e.backtrace.join("\n")
        end
      end

      private

      def build_step_stack(steps, last)
        steps.reverse_each do |step|
          previous_last = last
          last = proc {
            run_step(step, &previous_last)
          }
        end
        last
      end

      def run_step(step, &block)
        options = step["options"] || {}
        log Paint[(step["type"]).to_s, :green], bullet: :yellow unless options["quiet"]
        runner = "run_#{step["type"].gsub(/[:]/, "_")}_step"
        if respond_to?(runner, true)
          send(runner, options, &block)
        else
          raise "don't know how to handle step: #{step.inspect} - define #{runner} ?"
        end
      end

      def log(msg, level: 0, bullet: :default)
        msg = TTY::Markdown.parse(msg)
        prefix = ""
        prefix += " " * (level * 2)
        prefix += Paint["• ", bullet] if bullet
        msg = msg.split("\n").map { |line| "#{prefix}#{line}" }.join("\n")
        puts msg.lstrip
      end

      def prompt
        @prompt ||= TTY::Prompt.new
      end

      # Run Steps

      def run_show_version_step(step)
        log "Current version: #{Paint[get_current_version, :cyan]}", bullet: :red
        yield
      end

      def run_bump_step(step)
        previous_version = get_current_version

        next_version = prompt.select("Select increment (next version)") { |menu|
          menu.choice "patch (#{bump(previous_version, :patch)})", bump(previous_version, :patch)
          menu.choice "minor (#{bump(previous_version, :minor)})", bump(previous_version, :minor)
          menu.choice "major (#{bump(previous_version, :major)})", bump(previous_version, :major)
          # Other, please specify...
          # todo: add other option
        }

        log Paint["bumping to #{next_version}", :cyan], bullet: false, level: 1
        update_version(next_version)
        @next_version = next_version
        yield
      rescue Exception => e
        if previous_version
          log Paint["rolling back bump to #{previous_version}", :yellow]
          update_version(previous_version, force: true)
        else
          warn "no previous_version set .. not rolling back bump"
        end
        raise e
      end

      def run_changelog_step(step)
        case step["using"]
        when "conventional-changelog"
          File.open("release.json", "w") { |fh| fh.write(JSON.dump({version: @next_version})) }
          begin
            log Paint["getting changelog ...", :cyan], level: 1, bullet: false
            @last_changelog = capture_shell("conventional-changelog --pkg release.json", indent: 4, echo_command: false, raise_on_error: true).strip
            @last_changelog.gsub!(/<small>(.+)<\/small>/, '\1')
            log @last_changelog, level: 2, bullet: false
            if step["update"]
              if prompt.yes?("update #{step["update"]}?")
                last_changelog_body = File.read(step["update"])
                run_shell("conventional-changelog --pkg release.json -s -i #{step["update"].inspect}", indent: 4)
              end
            end
          ensure
            File.unlink("release.json") if File.exist?("release.json")
          end
        else
          raise "don't know how to get changelog using: #{step["using"].inspect}"
        end
        yield
      rescue Exception => e
        log Paint["rolling back changelog ...", :yellow]
        if step["update"]
          if last_changelog_body
            log "write last changelog body to #{step["update"]}", level: 1
            File.open(step["update"], "w") { |fh| fh.write(last_changelog_body) }
          else
            log "no last changelog body", level: 1
          end
        else
          log "step has no update", level: 1
        end
        raise e
      end

      def run_git_commit_step(step)
        version = @next_version

        status = Git.status
        last_commit_sha = status["branch.oid"]
        if step["permit"]
          step["permit"].each do |fn|
            if status[:files][fn]
              # if prompt.yes?("Add #{fn} to git?")
              Git.add fn, echo: false
              # end
            end
          end
          status = Git.status
          extra_files = []
          status[:files].each do |k, v|
            case v[:type]
            when :changed
              if step["permit"].include?(k)
                if v["XY"][1] != "."
                  extra_files << k
                  log Paint["#{k} - #{v[:type]} #{v["XY"].inspect}", :red]
                end
              else
                extra_files << k
                log Paint["#{k} - #{v[:type]}", :red]
              end
            else
              extra_files << k
              log Paint["#{k} - #{v[:type]}", :red]
            end
          end

          if extra_files.any?
            raise "extra files in diff! - #{extra_files.inspect}"
          end

          if status[:files].any?
            status[:files].each do |k, v|
              log "#{k} - #{v[:type]}", level: 2
            end
            if step["no_confirm"] || prompt.yes?("Commit?")
              message = step["message"].gsub("{{version}}", version)
              message_suffix = prompt.ask("What do want want to name this release? (#{message} - ?) [leave blank to ommit]", default: nil) if step["ask_message"]
              message += " - #{message_suffix}" if message_suffix
              Git.commit(message: message, echo: false)
              log "committed #{message}", level: 1
            end
          else
            log Paint["nothing to commit!", :red]
          end
        else
          raise ArgumentError, "step should specify permit! - #{step.inspect}"
        end
        yield
      rescue Exception => e
        if last_commit_sha
          log Paint["rolling back to #{last_commit_sha} ...", :yellow]
          Git.reset(last_commit_sha, hard: true)
        else
          log "no last_commit_sha", level: 1
        end
        raise e
      end

      def run_git_tag_step(step)
        version = @next_version
        if step["annotate"]
          message = step["annotate"].gsub("{{version}}", version).gsub("{{changelog}}", @last_changelog.to_s)
          if step["no_confirm"] || prompt.yes?("tag #{version}?")
            Git.tag(version, annotate: message, echo: false)
            log "tagged version #{version}", level: 1
          end
        else
          if step["no_confirm"] || prompt.yes?("tag #{version}?")
            Git.tag(version)
            log "tagged version #{version}", level: 1
          end
        end
        yield
      rescue Exception => e
        Git.delete_tag(version)
        raise e
      end

      def run_git_push_step(step)
        raise "step must specify remotes!" unless step["remotes"]

        step["remotes"].each_with_index do |remote, index|
          if remote.is_a?(String)
            step["remotes"][index] = {
              "remote" => remote,
            }
          end
        end

        remote_names = step["remotes"].map { |ri| ri["remote"] }

        branch = Git.current_branch

        previous_refs = {}
        done_remotes = {}

        remote_names.each do |remote|
          previous_refs[remote] = Git.rev_parse("#{remote}/#{branch}")
        end

        remotes = prompt.multi_select(
          "push to branches:",
          remote_names,
          default: (1..remote_names.length).to_a,
          help: ""
        )

        remotes.each do |remote_name|
          remote_info = step["remotes"].find { |r| r["remote"] == remote_name }
          done_remotes[remote_name] = true
          Git.push(remote: remote_name, dst: branch, quiet: true, force: remote_info["force"])
        end

        yield
      rescue Exception => e
        previous_refs.each do |remote, ref|
          if done_remotes[remote]
            Git.push(src: ref, remote: remote, dst: branch, force: true, quiet: true)
            Git.push(src: "", remote: remote, dst: @next_version)
          end
        end
        raise e
      end

      def run_git_fetch_step(step)
        log Paint["fetching from remotes: #{step["remotes"].join(", ")}", :cyan], level: 1
        Git.fetch_multiple(step["remotes"], quiet: true, echo: false)
        yield
      rescue Exception => e
        raise e
      end

      def run_git_no_dirty_step(step)
        status = Git.status
        extra_files = []
        status[:files].each do |k, v|
          extra_files << k
          log Paint["#{k} - #{v[:type]}", :red]
        end

        if extra_files.any?
          abort "dirty working directory - #{extra_files.inspect}"
        end

        yield
      end

      ############

      def bump(version, level)
        v = version.split(".")
        case level
        when :major
          v = [v[0].to_i + 1, 0, 0]
        when :minor
          v = [v[0], v[1].to_i + 1, 0]
        when :patch
          v = [v[0], v[1], v[2].to_i + 1]
        end
        v.join(".")
      end

      def options
        config["options"] || {}
      end

      def update_version(new_version, force: false)
        if options["version"] && options["version"]["update"]
          options["version"]["update"].each do |what|
            case what
            when "git:tag"
              # nothing to do
            when "package.json"
              if force || prompt.yes?("Do you want to update package.json with version #{new_version}?")
                data = JSON.parse(File.read("package.json"))
                data["version"] = new_version
                File.open("package.json", "w") do |fh|
                  fh.write(JSON.pretty_generate(data) + "\n")
                end
              end
            else
              raise "Don't know how to set version to #{source.inspect}"
            end
          end
        else
          raise "can't set version without version update specified!"
        end
      end

      def get_current_version
        version = nil

        if options["version"] && options["version"]["source"]
          options["version"]["source"].each do |source|
            case source
            when "git:tag"
              version = Git.current_tag
            when "package.json"
              version = JSON.parse(File.read("package.json"))["version"]
              break if version
            else
              raise "Don't know how to get version from #{source.inspect}"
            end
          end
        else
          raise "can't get current version without version source specified!"
        end

        version
      end

      def config
        @config ||= begin
          fn = ".release.yml"
          raise "#{fn}} not found!" unless File.exist?(fn)
          YAML.load_file(fn)
        end
      end
    end
  end
end
