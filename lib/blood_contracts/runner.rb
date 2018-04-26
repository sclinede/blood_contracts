require_relative "round"
require_relative "runners/validator"
require_relative "runners/matcher"
require_relative "runners/statistics"
require_relative "contracts/description"

module BloodContracts
  class Runner
    extend Dry::Initializer

    option :contract_hash
    option :sampler
    option :statistics
    option :context, optional: true

    # FIXME: block argument is not under tracking.
    def call(args:, kwargs:, output: "", meta: {}, error: nil)
      (output, meta, error = yield(meta)) if block_given?
      round = Round.new(
        input: { args: args, kwargs: kwargs },
        output: output, error: error, meta: meta
      )
      matcher.call(round) do |rules|
        Array(rules).each(&statistics.method(:increment))
        sampler.store(round: round, rules: rules, context: context)
        validate!(rules, round)
      end
    end

    def validate!(rules, round)
      Runners::Validator.new(contract_hash, rules, round).call
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

    def matcher
      Runners::Matcher.new(contract_hash)
    end

    def contract_description
      Contracts::Description.call(contract_hash)
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
