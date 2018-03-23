module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(input, output, meta, error = nil, storage:)
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

        try_reraise error
        !storage.found_unexpected_behavior?
      end

      private

      def try_reraise(error)
        error ||= {}
        raise error unless error.respond_to?(:to_hash)
        warn(<<~TEXT) unless error.empty?
          Skipped raise of #{error.keys.first} while debugging
        TEXT
      end

      def wrap_error(exception)
        return {} if exception.to_s.empty?
        return exception.to_h if exception.respond_to?(:to_hash)
        {
          exception.class.to_s => {
            message: exception.message,
            backtrace: exception.backtrace,
          }
        }
      end

      def select_matched_rules!(round)
        contract_hash.select do |name, rule|
          rule.check.call(round)
        end
      end
    end
  end
end
