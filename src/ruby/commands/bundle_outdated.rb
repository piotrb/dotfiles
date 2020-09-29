module Commands
  module BundleOutdated
    extend CommandHelpers

    class << self
      def init
        require "yaml"
      end

      def run(argv)
        puts "Getting outdated gems ..."
        output = clean_env(type: :ruby) { `bundle outdated --parseable` }
        lines = output.split("\n").map(&:strip).reject(&:empty?)
        packages = lines.map { |line| parse_line(line) }
        attach_urls(packages)

        table = TTY::Table.new(header: ["Name", "Installed", "Newest", "Requested", "Url"])
        packages.each do |pkg|
          table << [
            colorized_name(pkg),
            pkg.installed,
            colorized_newest_version(pkg),
            pkg.requested,
            best_url(pkg),
          ]
        end

        puts table.renderer(:unicode, padding: [0, 1, 0, 1]).render
      end

      private

      def parse_line(line)
        match = line.match(/^(?<name>[^ ]+) \((?<options>.+)\)$/)
        package = Hashie::Mash.new({
          name: match[:name],
        })
        parts = match[:options].split(/(newest|installed|requested)/).reject(&:empty?).map { |i| i.gsub(/, $/, "").strip }
        package.merge! Hash[*parts]

        package.level = :none

        newest = Gem::Version.new(package.newest)
        installed = Gem::Version.new(package.installed)

        diff_at = []

        [newest.segments.length, installed.segments.length].max.times do |i|
          diff_at[i] = (newest.segments[i] != installed.segments[i])
        end

        package.diff_at = diff_at

        package.level = if diff_at[0]
          :major
        elsif diff_at[1]
          :minor
        elsif diff_at[2]
          :patch
        else
          :other
        end

        package
      end

      def color_map
        {
          none: :white,
          major: :red,
          minor: :yellow,
          patch: :blue,
          other: :cyan,
        }
      end

      def colorized_newest_version(package)
        newest = Gem::Version.new(package.newest)

        color = color_map[package.level]

        color_rest = false

        newest.segments.map.with_index { |s, i|
          if package.diff_at[i] || color_rest
            color_rest = true
            Paint[s, color]
          else
            s
          end
        }.join(".")
      end

      def colorized_name(package)
        Paint[package.name, color_map[package.level]]
      end

      def attach_urls(packages)
        puts "Gathering package info ..."
        packages.each do |pkg|
          spec = Gem::Specification.find_by_name(pkg.name)
          pkg.homepage = spec.homepage
          pkg.summary = spec.summary
          pkg.changelog_uri = spec.metadata["changelog_uri"]
          pkg.source_code_uri = spec.metadata["source_code_uri"]
        rescue Gem::MissingSpecError => e
          p "skipping #{pkg.name} - #{e.class}: #{e.message}"
        end
      end

      def overide_url_data
        @overide_url_data ||= begin
          path = File.expand_path("~/.gem/changelog_urls.yaml")
          if File.exist?(path)
            YAML.load_file(path)
          else
            {}
          end
        end
      end

      def override_url_for(package)
        overide_url_data[package.name]
      end

      def best_url(package)
        if override_url_for(package)
          override_url_for(package)
        elsif package.changelog_uri
          package.changelog_uri
        elsif package.source_code_uri
          warn "[warn] no changelog url for package: #{package.name} (using source code uri)"
          "[source] " + package.source_code_uri
        elsif package.homepage
          warn "[warn] no changelog url for package: #{package.name} (using homepage)"
          "[home] " + package.homepage
        else
          warn "[warn] no uri for package: #{package.name}"
          ""
        end
      end
    end
  end
end
