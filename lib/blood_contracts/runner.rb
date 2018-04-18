require_relative "round"
require_relative "runners/validator"
require_relative "runners/matcher"
require_relative "runners/statistics"
require_relative "contracts/description"

module BloodContracts
  class Runner
    extend Dry::Initializer

    option :contract
    option :sampler
    option :statistics
    option :context, optional: true
    option :matcher, default: -> { Runners::Matcher.new(contract) }

    # FIXME: block argument is missing.
    def call(args:, kwargs:, output: "", meta: {}, error: nil)
      (output, meta, error = yield(meta)) if block_given?
      round = Round.new(
        input: {
          args: args.map(&:to_s),
          kwargs: kwargs.transform_values(&:to_s)
        },
        output: output, error: error, meta: meta
      )
      matcher.call(round) do |rules|
        Array(rules).each(&statistics.method(:store))
        sampler.store(round: round, rules: rules, context: context)
        raise_exception(round) unless valid?(rules)
      end
    end

    def valid?(rules)
      Runners::Validator.new(contract, rules, statistics).valid?
    end

    # FIXME: Move to locales
    def failure_message
      intro = "expected that given Proc would meet the contract:"
      "#{intro}\n#{contract_description}\n#{statistics}"\
      "For further investigations check storage (#{sampler.storage.class}): "\
      "#{suggestion}"
    end

    # FIXME: Move to locales
    def description
      "meet the contract:\n#{contract_description} \n#{statistics}"\
      "For further investigations check storage (#{sampler.storage.class}): "\
      "#{suggestion}\n"
    end
    alias :to_s :description

    protected

    def raise_exception(round)
      return unless BloodContracts.config.raise_on_failure
      if statistics.guarantees_failed?
        raise BloodContracts::GuaranteesFailure, round.to_h
      elsif statistics.found_unexpected_behavior?
        raise BloodContracts::ExpectationsFailure, round.to_h
      end
    end

    def contract_description
      @contract_description ||= Contracts::Description.call(contract)
    end

    def suggestion
      if statistics.found_unexpected_behavior?
        "[session_name=#{sampler.session},"\
        "rule=#{BloodContracts::UNEXPECTED_BEHAVIOR}]"
      else
        "[session_name=#{sampler.session}}]"
      end
    end
  end
end
