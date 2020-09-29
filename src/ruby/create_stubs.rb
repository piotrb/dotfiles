#!env ruby
require "fileutils"

puts "Detecting Environment ..."
env_location = `which env`.strip
puts "env: #{env_location}"

def render_stub(comment:, script_name:, env_location:)
  [
    "#!#{env_location} ruby",
    "",
    "# this is an auto-generated stub for ruby executables",
    "",
    comment,
    comment && "",
    "require_relative '../src/ruby/init'",
    "execute_command(#{script_name.to_sym.inspect}, ARGV)",
    "",
  ].compact.join("\n")
end

puts ""
puts "Finding existing stubs ..."
existing = []
Dir["../../bin/*"].each do |file|
  if File.size(file) < 1024
    data = File.read(file)
    if data.match("src/ruby/init") && data.match("execute_command")
      existing << File.basename(file)
    end
  end
end
puts "Found #{existing.length} existing stubs ..."

puts ""
puts "Updating stubs ..."

Dir["commands/*.rb"].each do |cmd|
  ext = File.extname(cmd)
  script_name = File.basename(cmd, ext)
  exe_name = script_name.tr("_", "-")
  comment = if File.exist?("commands/#{script_name}.txt")
    File.read("commands/#{script_name}.txt").strip
  end

  body = render_stub(comment: comment, script_name: script_name, env_location: env_location)

  puts "writing #{exe_name} ..."
  existing -= [exe_name]
  File.open("../../bin/#{exe_name}", "w") { |fh| fh.write(body) }
  FileUtils.chmod 0o755, "../../bin/#{exe_name}"
end

if existing.length > 0
  puts ""
  puts "Found #{existing.length} leftover stubs ..."
  existing.each do |exe_name|
    puts " - removing #{exe_name}"
    File.unlink("../../bin/#{exe_name}")
  end
end
