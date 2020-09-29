#!env ruby
require "active_support/all"

list = $stdin.readlines.map(&:strip).reject(&:blank?).map do |line|
  body = line.split("#", 2).first
  command, file = body.split(" ", 2)
  file = file.split(":", 2).first
  [command.strip, file.strip]
end

list.group_by(&:first).each do |command, files|
  files = files.map(&:last).uniq
  system "bundle exec #{command} #{files.join(" ")}"
end
