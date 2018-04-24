module BloodContracts
  module Statistics
    class Validator
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }
      param :statistics

      def valid?
        return true unless statistics.current_period.closed?
        current_period_statistics = statistics.current_period
        statistics_guarantees.all? do |rule, check|
          check.call(current_period_statistics[rule.name], rule)
        end
      end

      private

      def statistics_guarantees
        Hash[
          contract_hash.map do |name, rule|
            rule = rule.merge(name: name)
            next [rule, method(:between_check)] if rule.threshold && rule.limit
            next [rule, method(:threshold_check)] if rule.threshold
            next [rule, method(:limit_check)] if rule.limit
            [rule, method(:anyway)]
          end
        ]
      end

      def between_check(value, rule)
        value = value&.percent || 0.0
        value > rule.threshold && value <= rule.limit
      end

      def threshold_check(value, rule)
        value = value&.percent || 0.0
        value > rule.threshold
      end

      def limit_check(value, rule)
        value = value&.percent || 0.0
        value <= rule.limit
      end

      def anyway(_value, _rule)
        true
      end
    end
  end
end
