module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(input, output, meta = Hash.new, storage:)
        options = Hashie::Mash.new(input: input, output: output, meta: meta)

        rule_names = select_matched_rules!(options).keys
        rule_names = [Storage::UNDEFINED_RULE] if rule_names.empty?
        Array(rule_names).each(&storage.method(:store))

        yield rule_names, options if block_given?

        !storage.found_unexpected_behavior?
      end

      private

      def with_rule_options(rule_name, options)
        rule_options = options.shallow_merge(meta: {})
        result = yield(rule_options)
        options.meta.merge!(rule_name.to_sym => rule_options.meta)
        result
      end

      def select_matched_rules!(options)
        contract_hash.select do |name, rule|
          with_rule_options(name, options) do |rule_options|
            rule.check.call(rule_options)
          end
        end
      end
    end
  end
end
