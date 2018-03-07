require_relative "contracts/validator"
require_relative "contracts/matcher"
require_relative "contracts/description"

module BloodContracts
  class Runner
    extend Dry::Initializer

    param :checking_proc

    option :suite
    option :storage, default: -> { suite.storage }

    option :iterations, ->(v) do
      v = ENV["iterations"] if ENV["iterations"]
      v.to_i.positive? ? v.to_i : 1
    end, default: -> { 1 }
    option :time_to_run, ->(v) do
      v = ENV["duration"] if ENV["duration"]
      v.to_f if v.to_f.positive?
    end, optional: true

    option :context, optional: true
    option :stop_on_unexpected, default: -> { false }

    option :statistics, default: -> { Statistics.new(iterations) }
    option :matcher,   default: -> { Contracts::Matcher.new(suite.contract) }
    option :validator, default: -> { Contracts::Validator.new(suite.contract) }
    option :contract_description, default: -> do
      Contracts::Description.call(suite.contract)
    end

    def call
      iterate do
        next if match_rules?(matches_storage: statistics) do
          input = suite.data_generator.call
          [input, checking_proc.call(input)]
        end
        throw :unexpected_behavior, :stop if stop_on_unexpected
      end
      return if stopped_by_unexpected_behavior?

      validator.valid?(statistics)
    end

    # FIXME: Move to locales
    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if validator.expected_behavior?
        "#{intro}\n#{contract_description}\n"\
          " during #{iterations} run(s) but got:\n#{statistics}\n\n"\
          "For further investigations open: #{storage.suggestion}"
      else
        "#{intro}\n#{contract_description}\n"\
        " during #{iterations} run(s) but got unexpected behavior.\n\n"\
        "For further investigations open: #{storage.unexpected_suggestion}"
      end
    end

    # FIXME: Move to locales
    def description
      "meet the contract:\n#{contract_description} \n"\
      " during #{iterations} run(s). Stats:\n#{statistics}\n\n"\
      "For further investigations open: #{storage.suggestion}\n"
    end

    protected

    def match_rules?(matches_storage:)
      matcher.call(*yield, storage: matches_storage) do |rules, options|
        storage.store(options: options, rules: rules, context: context)
      end
    rescue StandardError => error
      # FIXME: Possible recursion?
      # Write test about error in the storage#store (e.g. writing error)
      store_exception(error, input, output, context)
      raise
    end

    def stopped_by_unexpected_behavior?
      @_stopped_by_unexpected_behavior == :stop
    end

    def iterate
      run_iterations ||= iterations

      if time_to_run
        run_iterations = iterations_count_from_time_to_run { yield }
        @iterations = run_iterations + 1
      end

      @_stopped_by_unexpected_behavior = catch(:unexpected_behavior) do
        run_iterations.times { yield }
      end
    end

    def iterations_count_from_time_to_run
      time_per_action = Benchmark.measure { yield }
      (time_to_run / time_per_action.real).ceil
    end

    def store_exception(error, input, output, context)
      storage.store(
        options: {
          input: input,
          output: output || {},
          meta: {exception: error},
        },
        rules: [Storage::EXCEPTION_CAUGHT],
        context: context,
      )
    end
  end
end
