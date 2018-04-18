module BloodContracts
  module Runners
    class Validator
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }
      param :rules, method(:Array)
      param :statistics

      ALL_INVALID_RULES = [
        BloodContracts::GUARANTEE_FAILURE,
        BloodContracts::UNEXPECTED_BEHAVIOR,
        BloodContracts::UNEXPECTED_EXCEPTION
      ]

      def valid?
        (rules & ALL_INVALID_RULES).empty?
        # return true unless statistics.period_just_closed?
        #
        # last_run_stats = statistics.to_h
        # statistics_expectations.all? do |rule, check|
        #   percent = last_run_stats[rule.name]&.percent || 0.0
        #   check.call(percent, rule)
        # end
      end

      private

      def statistics_expectations
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
        value > rule.threshold && value <= rule.limit
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
