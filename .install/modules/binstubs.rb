# frozen_string_literal: true

require 'fileutils'
require_relative './_common'

module BinstubsModule
  include CommonModule

  STUB_MARKER = '# @generated binstubs'
  REPO = File.expand_path('../..', __dir__)

  GITIGNORE_BEGIN = '# >>> generated stubs (managed by binstubs) >>>'
  GITIGNORE_BEGIN_LEGACY = '# >>> generated stubs (managed by src/make_stubs.rb) >>>'
  GITIGNORE_END = '# <<< generated stubs <<<'

  # ---- name helpers --------------------------------------------------------

  def exe_name(name)
    name.tr('_', '-')
  end

  # ---- stub content generators ---------------------------------------------

  def ruby_stub_content(name)
    init = File.join(REPO, 'src/ruby/init.rb')
    <<~SH
      #!/bin/bash -l
      #{STUB_MARKER}
      mise exec -- ruby -r #{init} -e 'execute_command(#{name.to_sym.inspect}, ARGV);' "$@"
    SH
  end

  def node_stub_content(name)
    node_dir = File.join(REPO, 'src/node')
    <<~SH
      #!/bin/bash
      #{STUB_MARKER}
      cd #{node_dir.inspect} || exit 1
      exec ./node_modules/.bin/ts-node #{"src/#{name}.ts".inspect} "$@"
    SH
  end

  def python_stub_content(name, venv_python)
    script = File.join(REPO, "src/python/#{name}.py")
    <<~SH
      #!/bin/bash
      #{STUB_MARKER}
      exec #{venv_python.inspect} #{script.inspect} "$@"
    SH
  end

  def stub_content(type, name, venv_python: nil)
    case type
    when 'ruby'   then ruby_stub_content(name)
    when 'node'   then node_stub_content(name)
    when 'python' then python_stub_content(name, venv_python)
    else raise ArgumentError, "unknown stub type: #{type}"
    end
  end

  # ---- gitignore helpers ---------------------------------------------------

  def gitignore_begin?(line)
    line == GITIGNORE_BEGIN || line == GITIGNORE_BEGIN_LEGACY
  end

  def gitignore_managed_entries(gitignore_path)
    return [] unless File.exist?(gitignore_path)

    inside = false
    File.readlines(gitignore_path, chomp: true).filter_map do |line|
      if gitignore_begin?(line)
        inside = true
        next
      elsif line == GITIGNORE_END
        inside = false
        next
      end
      line.delete_prefix('/') if inside && !line.strip.empty?
    end
  end

  def gitignore_manual_lines(gitignore_path)
    return [] unless File.exist?(gitignore_path)

    inside = false
    kept = File.readlines(gitignore_path, chomp: true).reject do |line|
      if gitignore_begin?(line) then inside = true; true
      elsif line == GITIGNORE_END then was = inside; inside = false; was
      else inside
      end
    end
    kept.pop while kept.last&.strip&.empty?
    kept
  end

  def rewrite_gitignore(gitignore_path, entries)
    manual = gitignore_manual_lines(gitignore_path)
    block = [GITIGNORE_BEGIN, *entries.sort.map { |e| "/#{e}" }, GITIGNORE_END]
    content = (manual + (manual.empty? ? [] : ['']) + block).join("\n") + "\n"
    File.write(gitignore_path, content)
  end

  # ---- evaluate ------------------------------------------------------------

  def evaluate(dest_dir) # rubocop:disable Metrics/MethodLength
    dest_dir = File.expand_path(dest_dir, Dir.pwd)
    gitignore_path = File.join(dest_dir, '.gitignore')

    venv = ENV['VIRTUAL_ENV']
    venv_python = venv && !venv.empty? ? File.join(venv, 'bin', 'python') : nil

    known_exes = []
    current_gitignore = gitignore_managed_entries(gitignore_path)

    with_plan do |plan|
      # Ruby
      Dir[File.join(REPO, 'src/ruby/commands/*/main.rb')].sort.each do |source|
        name = File.basename(File.dirname(source))
        exe = exe_name(name)
        known_exes << exe

        stub_path = File.join(dest_dir, exe)
        expected = ruby_stub_content(name)
        unless File.exist?(stub_path) && File.read(stub_path) == expected
          plan << action(:write_stub, 'ruby', name, dest_dir: dest_dir)
        end

        plan << action(:gitignore_add, gitignore_path, exe) unless current_gitignore.include?(exe)
      end

      # Node
      Dir[File.join(REPO, 'src/node/src/*.ts')].sort.each do |source|
        name = File.basename(source, '.ts')
        exe = exe_name(name)
        known_exes << exe

        stub_path = File.join(dest_dir, exe)
        expected = node_stub_content(name)
        unless File.exist?(stub_path) && File.read(stub_path) == expected
          plan << action(:write_stub, 'node', name, dest_dir: dest_dir)
        end

        plan << action(:gitignore_add, gitignore_path, exe) unless current_gitignore.include?(exe)
      end

      # Python
      Dir[File.join(REPO, 'src/python/*.py')].sort.each do |source|
        name = File.basename(source, '.py')
        exe = exe_name(name)
        known_exes << exe

        raise 'VIRTUAL_ENV is not set — run with the repo direnv active' unless venv_python

        stub_path = File.join(dest_dir, exe)
        expected = python_stub_content(name, venv_python)
        unless File.exist?(stub_path) && File.read(stub_path) == expected
          plan << action(:write_stub, 'python', name, dest_dir: dest_dir, venv_python: venv_python)
        end

        plan << action(:gitignore_add, gitignore_path, exe) unless current_gitignore.include?(exe)
      end

      # Orphan stubs — scan dest_dir for files carrying the stub marker
      Dir[File.join(dest_dir, '*')].sort.each do |stub_path|
        next unless File.file?(stub_path) && File.executable?(stub_path)
        next unless File.read(stub_path).include?(STUB_MARKER)

        exe = File.basename(stub_path)
        next if known_exes.include?(exe)

        plan << action(:prune_stub, stub_path)
      end

      # Orphan gitignore entries
      current_gitignore.sort.each do |exe|
        next if known_exes.include?(exe)

        plan << action(:gitignore_remove, gitignore_path, exe)
      end
    end
  end

  module Actions
    module ActionProxy
      def format_for_print_for_write_stub
        type, name = @args
        "[#{type}] #{name.tr('_', '-')}"
      end

      def format_for_print_for_prune_stub
        "[prune] #{File.basename(@args[0])}"
      end

      def format_for_print_for_gitignore_add
        "add  /#{@args[1]}"
      end

      def format_for_print_for_gitignore_remove
        "remove /#{@args[1]}"
      end
    end

    def write_stub(type, name, dest_dir:, venv_python: nil)
      content = stub_content(type, name, venv_python: venv_python)
      exe = exe_name(name)
      path = File.join(dest_dir, exe)
      puts "  write [#{type}]: #{path}"
      File.write(path, content)
      FileUtils.chmod(0o755, path)
    end

    def prune_stub(stub_path)
      puts "  prune: #{stub_path}"
      FileUtils.rm_f(stub_path)
    end

    def gitignore_add(gitignore_path, exe)
      entries = gitignore_managed_entries(gitignore_path)
      return if entries.include?(exe)

      rewrite_gitignore(gitignore_path, entries + [exe])
    end

    def gitignore_remove(gitignore_path, exe)
      entries = gitignore_managed_entries(gitignore_path)
      return unless entries.include?(exe)

      rewrite_gitignore(gitignore_path, entries - [exe])
    end
  end
end

ModuleRegistry.register_module :binstubs, BinstubsModule
