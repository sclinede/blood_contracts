module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(input, output, meta, error = {}, storage:)
        round = Round.new(
          input: input, output: output, error: wrap_error(error), meta: meta,
        )
        rule_names = select_matched_rules!(round).keys
        if rule_names.empty?
          if error.present?
            rule_names = [Storage::EXCEPTION_CAUGHT]
          else
            rule_names = [Storage::UNDEFINED_RULE]
          end
        end
        Array(rule_names).each(&storage.method(:store))

        yield rule_names, round if block_given?

        raise error if error.present?
        !storage.found_unexpected_behavior?
      end

      private

      def wrap_error(exception)
        {
          exception.class.to_s => {
            message: exception.message,
            backtrace: exception.backtrace,
          }
        }
      end

      def select_matched_rules!(round)
        contract_hash.select do |name, rule|
          round.with_sub_meta(name) { |sub_round| rule.check.call(sub_round) }
        end
      end
    end
  end
end
