require_relative "./command_helpers"

module Git
  include CommandHelpers

  def current_branch
    capture_shell("git rev-parse --abbrev-ref HEAD", echo_command: false).strip
  end

  def current_tag
    capture_shell("git describe --abbrev=0", echo_command: false, raise_on_error: true).strip
  end

  def get_config(name)
    capture_shell("git config #{shell_escape(name)}", echo_command: false, error: false).strip
  end

  def set_config(name, value)
    run_shell("git config #{shell_escape(name)} #{shell_escape(value)}")
  end

  def dirty?
    run_shell("git diff --stat head", quiet: true, echo_command: false, return_status: true) > 0
  end

  def branch_exists?(name)
    capture_shell("git rev-parse --verify #{shell_escape(name)}", error: false, echo_command: false).strip != ""
  end

  def delete_branch(name, force: false)
    flag = force ? "-D" : "-d"
    run_shell("git branch #{flag} #{shell_escape(name)}")
  end

  def fetch(remote, quiet: false)
    run_shell("git fetch #{shell_escape(remote)}", quiet: quiet)
  end

  def fetch_multiple(remotes, quiet: false, echo: true)
    cmd = [
      "git fetch",
      "--multiple",
      remotes.map { |r| shell_escape(r) }.join(" "),
      "--no-prune-tags",
      quiet ? "--quiet" : nil,
    ].compact.join(" ")
    run_shell cmd, echo_command: echo
  end

  def rev_parse(ref)
    capture_shell("git rev-parse #{shell_escape(ref)}", raise_on_error: true, echo_command: false).strip
  end

  def checkout(ref = nil, to_branch: nil, quiet: false)
    cmd = [
      "git checkout",
      quiet ? "-q" : nil,
      ref ? shell_escape(ref) : nil,
      to_branch ? "-b #{to_branch}" : nil,
    ]
    run_shell cmd.compact.join(" ")
  end

  def commit(message:, echo: true)
    cmd = [
      "git commit",
      "-m #{shell_escape(message)}",
    ].join(" ")
    run_shell cmd, echo_command: echo
  end

  def rebase(upstream, branch = nil, interactive: false, return_status: false)
    cmd = [
      "git rebase",
      interactive ? "-i" : nil,
      upstream ? shell_escape(upstream) : nil,
      branch ? shell_escape(branch) : nil,
    ]
    run_shell cmd.compact.join(" "), return_status: return_status
  end

  def merge(ref, ff: nil, edit: nil)
    cmd = [
      "git merge",
      ff.nil? ? nil : (ff ? "--ff" : "--no-ff"), # rubocop:disable Style/NestedTernaryOperator
      edit.nil? ? nil : (edit ? "--edit" : "--no-edit"), # rubocop:disable Style/NestedTernaryOperator
      shell_escape(ref),
    ]
    run_shell cmd.compact.join(" "), quiet: true
  end

  def reset(ref, hard: false)
    cmd = [
      "git reset",
      hard ? "--hard" : nil,
      shell_escape(ref),
    ]
    run_shell cmd.compact.join(" ")
  end

  def add(path, echo: true)
    run_shell "git add #{shell_escape(path)}", echo_command: echo
  end

  def tag(name, annotate: nil, echo: true)
    cmd = [
      "git tag",
      shell_escape(name),
      annotate ? "-a -m #{shell_escape(annotate)}" : nil,
    ].compact.join(" ")
    run_shell cmd, echo_command: echo
  end

  def delete_tag(name)
    run_shell "git tag -d #{shell_escape(name)}"
  end

  def push(src: nil, remote: nil, dst: nil, force: false, quiet: false)
    ref = src ? (dst ? "#{src}:#{dst}" : src) : dst

    cmd = [
      "git push",
      remote ? shell_escape(remote) : nil,
      ref,
      "--follow-tags",
      force ? "--force" : nil,
      quiet ? "--quiet" : nil,
    ].compact.join(" ")
    run_shell cmd
  end

  def status
    result = {
      files: {},
      # changed: [],
      # renamed: [],
      # unmerged: [],
      # untracked: [],
      # ignored: [],
    }

    changes = capture_shell("git status --porcelain=v2 --branch", echo_command: false, raise_on_error: true).split("\n")
    changes.each do |line|
      case line
      when /^# (?<key>[^ ]+) (?<value>.+)$/
        result[$~[:key]] = $~[:value]
      when /^1 (?<XY>..) (?<sub>....) (?<mH>\d+) (?<mI>\d+) (?<mW>\d+) (?<hH>[^ ]+) (?<hI>[^ ]+) (?<path>.+)$/
        # Ordinary changed entries have the following format:
        # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>

        # Field       Meaning
        # --------------------------------------------------------
        # <XY>        A 2 character field containing the staged and
        #             unstaged XY values described in the short format,
        #             with unchanged indicated by a "." rather than
        #             a space.
        # <sub>       A 4 character field describing the submodule state.
        #             "N..." when the entry is not a submodule.
        #             "S<c><m><u>" when the entry is a submodule.
        #             <c> is "C" if the commit changed; otherwise ".".
        #             <m> is "M" if it has tracked changes; otherwise ".".
        #             <u> is "U" if there are untracked changes; otherwise ".".
        # <mH>        The octal file mode in HEAD.
        # <mI>        The octal file mode in the index.
        # <mW>        The octal file mode in the worktree.
        # <hH>        The object name in HEAD.
        # <hI>        The object name in the index.
        # <path>      The pathname.  In a renamed/copied entry, this
        #             is the target path.

        match_data = $~
        result[:files][match_data[:path]] = {
          type: :changed,
        }.merge(match_data.named_captures)
      when /^2 (?<XY>..) (?<sub>....) (?<mH>\d+) (?<mI>\d+) (?<mW>\d+) (?<hH>[^ ]+) (?<hI>[^ ]+) (?<X>.)(?<score>\d+) (?<path>[^\t]+)\t(?<origPath>.+)$/
        # Renamed or copied entries have the following format:
        # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>

        # Field       Meaning
        # --------------------------------------------------------
        # (all of the fields from above and ...)
        # <X><score>  The rename or copy score (denoting the percentage
        #             of similarity between the source and target of the
        #             move or copy). For example "R100" or "C75".
        # <origPath>  The pathname in the commit at HEAD or in the index.
        #             This is only present in a renamed/copied entry, and
        #             tells where the renamed/copied contents came from.

        match_data = $~
        result[:files][match_data[:path]] = {
          type: :renamed,
        }.merge(match_data.named_captures)
      when /^u (?<xy>..) (?<sub>....) (?<m1>\d+) (?<m2>\d+) (?<m3>\d+) (?<mW>\d+) (?<h1>[^ ]+) (?<h2>[^ ]+) (?<h3>[^ ]+) (?<path>.+)$/
        # Unmerged entries have the following format; the first character is a "u" to distinguish from ordinary changed entries.
        # u <xy> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>

        # Field       Meaning
        # --------------------------------------------------------
        # <XY>        A 2 character field describing the conflict type
        #             as described in the short format.
        # <sub>       A 4 character field describing the submodule state
        #             as described above.
        # <m1>        The octal file mode in stage 1.
        # <m2>        The octal file mode in stage 2.
        # <m3>        The octal file mode in stage 3.
        # <mW>        The octal file mode in the worktree.
        # <h1>        The object name in stage 1.
        # <h2>        The object name in stage 2.
        # <h3>        The object name in stage 3.
        # <path>      The pathname.
        # --------------------------------------------------------

        match_data = $~
        result[:files][match_data[:path]] = {
          type: :unmerged,
        }.merge(match_data.named_captures)
      when /^? (?<path>.+)$/
        # Untracked items have the following format:
        # ? <path>

        match_data = $~
        result[:files][match_data[:path]] = {
          type: :untracked,
        }.merge(match_data.named_captures)
      when /^! (?<path>.+)$/
        # Ignored items have the following format:
        # ! <path>

        match_data = $~
        result[:files][match_data[:path]] = {
          type: :ignored,
        }.merge(match_data.named_captures)
      end
    end

    result
  end

  def shell_escape(str)
    Shellwords.escape(str)
  end

  extend self
end
