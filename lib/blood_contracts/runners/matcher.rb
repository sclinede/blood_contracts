module BloodContracts
  module Runners
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(round)
        round.meta[:checked_rules] = []
        rule_names = match_guarantees!(round)
        rule_names ||= match_expectations!(round)
        rule_names ||= fallback_rule(round)

        yield rule_names, round if block_given?

        round
      end

      private

      def fallback_rule(round)
        if round.error.empty?
          [BloodContracts::UNEXPECTED_BEHAVIOR]
        else
          [BloodContracts::UNEXPECTED_EXCEPTION]
        end
      end

      def match_guarantees!(round)
        guarantees = contract_hash.guarantees
        return if guarantees.all? do |(name, rule)|
          round.meta[:checked_rules] << name
          rules_stack = rule[:check].call(round).to_a
          rules_stack.shift.tap { guarantees.push(*rules_stack) }
        end
        [BloodContracts::GUARANTEE_FAILURE]
      end

      def match_expectations!(round)
        with_expectation_match do |match|
          expectations = contract_hash.expectations
          expectations.each do |(name, rule)|
            round.meta[:checked_rules] << name
            rules_stack = rule[:check].call(round).to_a
            match << name if rules_stack.shift
            expectations.push(*rules_stack)
          end
        end
      end

      def with_expectation_match
        match = Set.new
        yield(match)
        match.empty? ? nil : match.to_a
      end

      # def match_expectations!(round)
      #   match = []
      #   contract.class.expectations_rules.each do |rule_name, rule|
      #     result = rule[:check].call(round)
      #     if result.respond_to(:to_ary)
      #       match += result.to_a
      #     elsif result
      #       match << rule_name
      #     end
      #   end
      #   match.empty? ? nil : match
      # end
    end
  end
end
