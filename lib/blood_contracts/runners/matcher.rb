module BloodContracts
  module Runners
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(round)
        round.meta[:checked_rules] = []
        rule_names = match_guarantees!(round)
        rule_names ||= match_expectations!(round)
        rule_names ||= fallback_rules(round)

        yield rule_names, round if block_given?

        round
      end

      private

      def fallback_rules(round)
        if round.error.empty?
          [BloodContracts::UNEXPECTED_BEHAVIOR]
        else
          [BloodContracts::UNEXPECTED_EXCEPTION]
        end
      end

      def match_guarantees!(round)
        return if contract_hash.guarantees.all? do |name, rule|
          round.meta[:checked_rules] << name
          rule.check.call(round)
        end
        [BloodContracts::GUARANTEE_FAILURE]
      end

      def match_expectations!(round)
        match = Hash[
          contract_hash.expectations.select do |name, rule|
            round.meta[:checked_rules] << name
            rule.check.call(round)
          end
        ]
        match.empty? ? nil : match.keys
      end
    end
  end
end
