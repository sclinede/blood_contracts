module BloodContracts
  module Runners
    class Validator
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }
      param :rules, method(:Array)
      param :round

      def valid?
        (rules & ALL_INVALID_RULES).empty?
      end

      # rubocop:disable Metrics/LineLength, Metrics/AbcSize
      def call
        return true if valid?
        return false unless BloodContracts.config.raise_on_failure

        raise GuaranteesFailure, round.to_h if rules.include?(GUARANTEE_FAILURE)
        raise ExpectationsFailure, round.to_h if rules.include?(UNEXPECTED_BEHAVIOR)
        # FIXME: we have to output the `round` for the case, somewhere...
        raise round.raw_error if rules.include?(UNEXPECTED_EXCEPTION)
      end
      # rubocop:enable Metrics/LineLength, Metrics/AbcSize

      GUARANTEE_FAILURE = BloodContracts::GUARANTEE_FAILURE
      UNEXPECTED_BEHAVIOR = BloodContracts::UNEXPECTED_BEHAVIOR
      GuaranteesFailure = BloodContracts::GuaranteesFailure
      ExpectationsFailure = BloodContracts::ExpectationsFailure

      ALL_INVALID_RULES = [
        GUARANTEE_FAILURE, UNEXPECTED_BEHAVIOR, UNEXPECTED_EXCEPTION
      ].freeze
    end
  end
end
