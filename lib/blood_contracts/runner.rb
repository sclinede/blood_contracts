require_relative "contracts/validator"
require_relative "contracts/round"
require_relative "contracts/matcher"
require_relative "contracts/description"
require_relative "contracts/iterator"
require_relative "contracts/statistics"

module BloodContracts
  class Runner
    extend Dry::Initializer

    option :contract
    option :storage

    option :context, optional: true

    option :statistics, default: -> { Contracts::Statistics.new(storage) }
    option :matcher, default: -> { Contracts::Matcher.new(contract) }

    # FIXME: block argument is missing.
    def call(args:, kwargs:, output: "", meta: {}, error: nil)
      (output, meta, error = yield(meta)) if block_given?
      round = Contracts::Round.new(
        input: { args: args, kwargs: kwargs },
        output: output, error: error, meta: meta
      )
      matcher.call(round) do |rules|
        Array(rules).each(&statistics.method(:store))
        storage.store(round: round, rules: rules, context: context)
      end
    end

    def valid?
      Contracts::Validator.new(contract).valid?(statistics)
    end

    # FIXME: Move to locales
    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if statistics.found_unexpected_behavior?
        "#{intro}\n#{contract_description}\n#{statistics}"\
        "For further investigations check: #{unexpected_suggestion}"
      else
        "#{intro}\n#{contract_description}\n#{statistics}"\
          "For further investigations check: #{suggestion}"
      end
    end

    # FIXME: Move to locales
    def description
      "meet the contract:\n#{contract_description} \n#{statistics}"\
      "For further investigations check: #{suggestion}\n"
    end
    alias :to_s :description

    protected

    def contract_description
      @contract_description ||= Contracts::Description.call(contract)
    end

    def unexpected_suggestion
      storage.unexpected_suggestion
    end

    def suggestion
      storage.suggestion
    end

    def match_rules?; end
  end
end
