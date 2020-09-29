#!env ruby

require "pathname"

def run(cmd)
  puts "$ #{cmd}"
  system(cmd)
  raise "Failed" unless $?.success?
end

failing_files = STDIN.readlines.map do |line|
  path = line.gsub(/^rspec (.+):\d.+$/, '\1').strip
  pn = Pathname.new(path).expand_path
  pn = pn.relative_path_from(Pathname.new(Dir.getwd))
  pn.to_s
end.uniq

all_specs = Dir["spec/**/*_spec.rb"]

passing_specs = all_specs - failing_files

# p passing_specs

failing_files.each do |file|
  puts "Processing #{file} ..."
  puts "-----------------------------------"
  run("rspec-bisect.rb #{passing_specs.join(" ")} #{file}")
  exit
end

# p lines
# p all_specs
