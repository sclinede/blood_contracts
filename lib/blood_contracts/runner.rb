require_relative "contracts/validator"
require_relative "contracts/round"
require_relative "contracts/matcher"
require_relative "contracts/description"
require_relative "contracts/iterator"
require_relative "contracts/statistics"

module BloodContracts
  class Runner
    extend Dry::Initializer

    option :suite
    option :storage, default: -> { suite.storage }

    option :iterations, default: -> { 1 }
    option :time_to_run, optional: true
    option :stop_on_unexpected, default: -> { false }
    option :iterator, default: -> do
      Contracts::Iterator.new(iterations, time_to_run)
    end

    option :context, optional: true

    option :statistics, default: -> { Contracts::Statistics.new(iterator) }
    option :matcher,   default: -> { Contracts::Matcher.new(suite.contract) }
    option :validator, default: -> { Contracts::Validator.new(suite.contract) }
    option :contract_description, default: -> do
      Contracts::Description.call(suite.contract)
    end

    def call(*args, **kwargs)
      return false if catch(:unexpected_behavior) do
        iterator.next do
          next if match_rules?(matches_storage: statistics) do
            meta = {}
            begin
              [{ args: args, kwargs: kwargs }, yield(meta), meta]
            rescue StandardError => error
              [{ args: args, kwargs: kwargs }, "", meta, error]
            end
          end
          throw :unexpected_behavior, :halt if stop_on_unexpected
        end
      end == :halt
      validator.valid?(statistics)
    end

    # FIXME: Move to locales
    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if stats.unexpected_behavior?
        "#{intro}\n#{contract_description}\n"\
        " during #{iterator.count} run(s) but got unexpected behavior.\n\n"\
        "For further investigations open: #{storage.unexpected_suggestion}"
      else
        "#{intro}\n#{contract_description}\n"\
          " during #{iterator.count} run(s) but got:\n#{statistics}\n\n"\
          "For further investigations open: #{storage.suggestion}"
      end
    end

    # FIXME: Move to locales
    def description
      "meet the contract:\n#{contract_description} \n"\
      " during #{iterator.count} run(s). Stats:\n#{statistics}\n\n"\
      "For further investigations open: #{storage.suggestion}\n"
    end
    alias :to_s :description

    protected

    def match_rules?(matches_storage:)
      matcher.call(*yield, storage: matches_storage) do |rules, round|
        storage.store(round: round, rules: rules, context: context)
      end
    end
  end
end
