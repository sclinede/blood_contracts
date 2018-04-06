module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(round)
        rule_names = select_matched_rules!(round).keys
        if rule_names.empty?
          rule_names = if !round.error.empty?
                         [Storage::EXCEPTION_CAUGHT]
                       else
                         [Storage::UNDEFINED_RULE]
                       end
        end

        yield rule_names, round if block_given?

        round
      end

      private

      def add_exception_caught_rule!(rule_names, round)
        return unless rule_names.empty?
        return unless round.error.present?
      end

      def select_matched_rules!(round)
        contract_hash.select do |_name, rule|
          rule.check.call(round)
        end
      end
    end
  end
end
