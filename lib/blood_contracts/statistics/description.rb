module BloodContracts
  class Statistics
    class Description
      attr_reader :current_statistics, :rounds_count, :found_unexpected_behavior
      def initialize(statistics)
        @found_unexpected_behavior = statistics.found_unexpected_behavior?
        @rounds_count = statistics.current.values.sum
        @current_statistics = Hash[
          statistics.current.map do |rule_name, times|
            [rule_name, rule_stats(times)]
          end
        ]
      end

      def call
        per_rule_stats =
          current_statistics.map(&method(:rule_stats_description)).join("; \n")
        return "Nothing captured.\n\n" if per_rule_stats.empty?

        if found_unexpected_behavior
          " during #{rounds_count} run(s) got unexpected behavior, "\
          "stats:\n#{per_rule_stats}\n\n"
        else
          " during #{rounds_count} run(s) got stats:\n#{per_rule_stats}\n\n"
        end
      end

      private

      def rule_stats_description(stats)
        name, occasions = stats
        " - '#{name}' happened #{occasions.times} time(s) "\
        "(#{(occasions.percent * 100).round(2)}% of the time)"
      end

      def rule_stats(times)
        Hashie::Mash.new(times: times, percent: (times.to_f / rounds_count))
      end
    end
  end
end
