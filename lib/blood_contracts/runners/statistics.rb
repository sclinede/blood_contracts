module BloodContracts
  module Runners
    class Statistics
      attr_accessor :iterations_count
      attr_reader :storage, :trackable_rules

      def initialize(iterations_count = nil)
        # @storage = Hash.new(0)
        @iterations_count = (iterations_count || 1).to_i
        @storage = default_storage_klass.new(self, contract_name)
        @trackable_rules = Set.new
      end

      def counts
        return {} if trackable_rules.empty?
        storage.samples_count_per_rule(*trackable_rules)
      end

      # def store(rule)
      #   storage[rule] += 1
      # end
      def track(rule)
        trackable_rules.add(rule)
        storage.store(rule)
      end
      alias :store :track

      def to_h
        # Hash[storage.map { |rule_name, times| [rule_name, rule_stats(times)] }]
        Hash[counts.map { |rule_name, times| [rule_name, rule_stats(times)] }]
      end

      def to_s
        rule_stats = to_h.map(&method(:rule_stats_description)).join("; \n")
        return "Nothing captured.\n\n" if rule_stats.empty?

        if found_unexpected_behavior?
          " during #{iterations_count} run(s) but got unexpected behavior. "\
          "Stats:\n#{rule_stats}\n\n"
        else
          " during #{iterations_count} run(s) got:\n#{rule_stats}\n\n"
        end
      end

      def guarantees_failed?
        storage.key?(Storage::UNDEFINED_RULE)
      end

      def found_unexpected_behavior?
        storage.key?(Storage::UNDEFINED_RULE)
      end

      def caught_exception?
        storage.key?(Storage::EXCEPTION_CAUGHT)
      end

      private

      def rule_stats_description(stats)
        name, occasions = stats
        " - '#{name}' happened #{occasions.times} time(s) "\
        "(#{(occasions.percent * 100).round(2)}% of the time)"
      end

      def rule_stats(times)
        Hashie::Mash.new(times: times, percent: (times.to_f / iterations_count))
      end
    end
  end
end
