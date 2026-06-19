#!/usr/bin/env ruby
# frozen_string_literal: true

# Unified bin/ stub generator for all three script subsystems (ruby, node,
# python). Indexes each src/<lang> folder, writes a launcher stub into the
# top-level bin/ for every command, links it into ~/bin, and centrally manages
# bin/.gitignore so the generated stubs (which bake absolute, per-machine paths)
# are never committed.
#
# Assumes direnv is active for the repo (so the python venv is set up): the
# python venv interpreter is taken from $VIRTUAL_ENV. Aborts if it is missing.
#
# Run it from anywhere; paths are resolved relative to this file.

require 'fileutils'

REPO = File.expand_path('..', __dir__)
BIN_DIR = File.join(REPO, 'bin')
HOME_BIN = File.expand_path('~/bin')
GITIGNORE = File.join(BIN_DIR, '.gitignore')

BEGIN_MARK = '# >>> generated stubs (managed by src/make_stubs.rb) >>>'
END_MARK = '# <<< generated stubs <<<'

VENV = ENV['VIRTUAL_ENV']
abort 'VIRTUAL_ENV is not set — run with the repo direnv active (cd into the repo).' if VENV.nil? || VENV.empty?
VENV_PYTHON = File.join(VENV, 'bin', 'python')

def exe_name(raw)
  raw.tr('_', '-')
end

# --- discovery -------------------------------------------------------------

# ruby: src/ruby/commands/<name>/main.rb
def ruby_commands
  Dir[File.join(REPO, 'src/ruby/commands/*/main.rb')].map do |main|
    File.basename(File.dirname(main))
  end.sort
end

# node: src/node/src/<name>.ts (top-level files only)
def node_commands
  Dir[File.join(REPO, 'src/node/src/*.ts')].map do |ts|
    File.basename(ts, '.ts')
  end.sort
end

# python: src/python/<name>.py
def python_commands
  Dir[File.join(REPO, 'src/python/*.py')].map do |py|
    File.basename(py, '.py')
  end.sort
end

# --- stub rendering --------------------------------------------------------

def ruby_stub(name)
  init = File.join(REPO, 'src/ruby/init.rb')
  <<~SH
    #!/bin/bash -l
    mise exec -- ruby -r #{init} -e 'execute_command(#{name.to_sym.inspect}, ARGV);' "$@"
  SH
end

def node_stub(name)
  <<~SH
    #!/bin/bash
    cd #{File.join(REPO, 'src/node').inspect} || exit 1
    exec ./node_modules/.bin/ts-node #{"src/#{name}.ts".inspect} "$@"
  SH
end

def python_stub(name)
  <<~SH
    #!/bin/bash
    exec #{VENV_PYTHON.inspect} #{File.join(REPO, "src/python/#{name}.py").inspect} "$@"
  SH
end

# --- writing ---------------------------------------------------------------

def write_stub(exe, body)
  path = File.join(BIN_DIR, exe)
  File.write(path, body)
  FileUtils.chmod(0o755, path)
  link = File.join(HOME_BIN, exe)
  FileUtils.mkdir_p(HOME_BIN)
  FileUtils.ln_sf(path, link)
  path
end

def previous_generated
  return [] unless File.exist?(GITIGNORE)

  lines = File.readlines(GITIGNORE, chomp: true)
  inside = false
  lines.filter_map do |line|
    if line == BEGIN_MARK then inside = true; next
    elsif line == END_MARK then inside = false; next
    end
    line.sub(%r{\A/}, '') if inside && !line.strip.empty?
  end
end

def manual_gitignore_lines
  return [] unless File.exist?(GITIGNORE)

  lines = File.readlines(GITIGNORE, chomp: true)
  inside = false
  kept = lines.reject do |line|
    if line == BEGIN_MARK then inside = true; true
    elsif line == END_MARK then was = inside; inside = false; was
    else inside
    end
  end
  # drop a trailing blank that may have separated manual entries from the block
  kept.pop while kept.last && kept.last.strip.empty?
  kept
end

def write_gitignore(exes)
  manual = manual_gitignore_lines
  block = [BEGIN_MARK, *exes.sort.map { |e| "/#{e}" }, END_MARK]
  content = (manual + (manual.empty? ? [] : ['']) + block).join("\n") + "\n"
  File.write(GITIGNORE, content)
end

def untrack(exe)
  # If a stub is currently tracked, drop it from the index so .gitignore takes
  # effect. No-op for already-untracked files.
  system('git', '-C', REPO, 'rm', '--cached', '--quiet', '--ignore-unmatch',
         "bin/#{exe}", out: File::NULL, err: File::NULL)
end

# --- main ------------------------------------------------------------------

generated = []

{
  ruby: [ruby_commands, method(:ruby_stub)],
  node: [node_commands, method(:node_stub)],
  python: [python_commands, method(:python_stub)],
}.each do |lang, (names, renderer)|
  names.each do |name|
    exe = exe_name(name)
    write_stub(exe, renderer.call(name))
    untrack(exe)
    generated << exe
    puts "  [#{lang}] bin/#{exe}"
  end
end

# Prune stubs we generated previously but no longer do.
(previous_generated - generated).each do |exe|
  puts "  [prune] bin/#{exe}"
  FileUtils.rm_f(File.join(BIN_DIR, exe))
  link = File.join(HOME_BIN, exe)
  FileUtils.rm_f(link) if File.symlink?(link)
end

write_gitignore(generated)

puts "Generated #{generated.length} stub(s); venv python: #{VENV_PYTHON}"
