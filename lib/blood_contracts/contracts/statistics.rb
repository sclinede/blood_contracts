module BloodContracts
  module Contracts
    class Statistics
      extend Dry::Initializer
      param :iterator
      option :storage, default: -> { Hash.new(0) }

      def store(rule)
        storage[rule] += 1
      end

      def to_h
        Hash[storage.map { |rule_name, times| [rule_name, rule_stats(times)] }]
      end

      def to_s
        to_h.map do |name, occasions|
          " - '#{name}' happened #{occasions.times} time(s) "\
          "(#{(occasions.percent * 100).round(2)}% of the time)"
        end.join("; \n")
      end

      def found_unexpected_behavior?
        storage.key?(Storage::UNDEFINED_RULE)
      end

      private

      def rule_stats(times)
        Hashie::Mash.new(times: times, percent: (times.to_f / iterator.count))
      end
    end
  end
end
