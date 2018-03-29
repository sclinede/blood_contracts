module BloodContracts
  module Contracts
    class Statistics
      extend Dry::Initializer
      param :iterations_count, ->(v) { v.to_i }, default: -> { 1 }
      attr_writer :iterations_count

      option :storage, default: -> { Hash.new(0) }

      def store(rule)
        storage[rule] += 1
      end

      def to_h
        Hash[storage.map { |rule_name, times| [rule_name, rule_stats(times)] }]
      end

      def to_s
        rule_stats = to_h.map do |name, occasions|
          " - '#{name}' happened #{occasions.times} time(s) "\
          "(#{(occasions.percent * 100).round(2)}% of the time)"
        end.join("; \n")

        return "Nothing captured.\n\n" if rule_stats.empty?

        if found_unexpected_behavior?
          " during #{iterations_count} run(s) but got unexpected behavior. "\
          "Stats:\n#{rule_stats}\n\n"
        else
          " during #{iterations_count} run(s) got:\n#{rule_stats}\n\n"
        end
      end

      def found_unexpected_behavior?
        storage.key?(Storage::UNDEFINED_RULE)
      end

      private

      def rule_stats(times)
        Hashie::Mash.new(times: times, percent: (times.to_f / iterations_count))
      end
    end
  end
end
