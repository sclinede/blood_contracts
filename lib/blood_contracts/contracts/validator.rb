module BloodContracts
  module Contracts
    class Validator
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def valid?(statistics)
        return if statistics.found_unexpected_behavior?

        last_run_stats = statistics.to_h
        expectations.all? do |rule, check|
          percent = last_run_stats[rule.name]&.percent || 0.0
          check.call(percent, rule)
        end
      end

      private

      def expectations
        Hash[
          contract_hash.map do |name, rule|
            threshold = rule.threshold
            next [rule.merge(name: name), method(:threshold_check)] if threshold
            next [rule.merge(name: name), method(:limit_check)] if rule.limit
            [rule.merge(name: name), method(:anyway)]
          end
        ]
      end

      def threshold_check(value, rule)
        value > rule.threshold
      end

      def limit_check(value, rule)
        value <= rule.limit
      end

      def anyway(_value, _rule)
        true
      end
    end
  end
end
