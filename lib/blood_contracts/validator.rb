module BloodContracts
  class Validator
    extend Dry::Initializer

    param :rules, method(:Array)
    param :round

    def valid?
      (rules & ALL_INVALID_RULES).empty?
    end

    # rubocop:disable Metrics/LineLength, Metrics/AbcSize
    def call
      return true if valid?
      raise GuaranteesFailure, round.to_h if rules.include?(GUARANTEE_FAILURE)
      raise ExpectationsFailure, round.to_h if rules.include?(UNEXPECTED_BEHAVIOR)
      # FIXME: we have to output the `round` for the case, somewhere...
      # use logger ?
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

    class Middleware
      def call(_contract, round, rules, _context)
        Validator.new(rules, round).call
        yield
      end
    end
  end
end
