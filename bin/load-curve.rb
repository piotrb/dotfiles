#!env ruby
# frozen_string_literal: true

module Commands
  module LoadCurve
    class << self
      def run(_args)
        t = time_now

        duration = 2.hours
        interval = 5.minutes
        initial = 0.025

        max_load = 50

        puts %w[delta delta_f delta_r sin load].join("\t")

        delta = 0
        while delta < duration
          delta = time_now - t
          delta_f = delta / duration
          delta_r = (delta_f * (1 - (initial * 2))) + initial
          sin = Math.sin(delta_r * Math::PI)
          puts [
            delta,
            delta_f,
            delta_r,
            sin,
            sin * max_load
          ].map { |n| n.round(2) }.join("\t")

          concurrency = (sin * max_load).round

          cmd = %(siege -j --no-parser --time=#{interval}S -c #{concurrency} -A "Detectify" https://demo-s-cac1-ex1.jane.qa/_lb_status https://demo-s-cac1-ex1.jane.qa/login)
          puts "> #{cmd}"
          system cmd

          # sleep interval
        end
      end

      def time_now
        # @now ||= Time.now
        Time.now
      end

      def sleep(n)
        # time_now
        # @now += n
        Kernel.sleep n
      end
    end
  end
end

Commands::LoadCurve.run(ARGV)
