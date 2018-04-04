module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(round:, statistics:)
        rule_names = select_matched_rules!(round).keys
        if rule_names.empty?
          rule_names = if error.present?
                         [Storage::EXCEPTION_CAUGHT]
                       else
                         [Storage::UNDEFINED_RULE]
                       end
        end
        Array(rule_names).each(&statistics.method(:store))

        yield rule_names, round if block_given?

        round
      end

      private

      def select_matched_rules!(round)
        contract_hash.select do |_name, rule|
          rule.check.call(round)
        end
      end
    end
  end
end
