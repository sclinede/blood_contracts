module BloodContracts
  class Runner
    extend Dry::Initializer

    param :checking_proc

    option :iterations, ->(v) do
      v = ENV["iterations"] if ENV["iterations"]
      v.to_i.positive? ? v.to_i : 1
    end, default: -> { 1 }
    option :time_to_run, ->(v) do
      v = ENV["duration"] if ENV["duration"]
      v.to_f if v.to_f.positive?
    end, optional: true

    option :context, optional: true
    option :suite
    option :stop_on_unexpected, default: -> { false }
    option :stats, default: -> { Statistics.new(iterations) }
    option :contract, default: -> { Contract.new(suite.contract, stats) }

    def call
      iterate do
        next unless match_rules.empty?
        throw :unexpected_behavior, :stop if stop_on_unexpected
      end
      valid?
    end

    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if stats.found_unexpected_behavior?
        "#{intro}\n#{contract}\n"\
        " during #{iterations} run(s) but got unexpected behavior.\n\n"\
        "For further investigations open: #{unexpected_further_investigation}"
      else
        "#{intro}\n#{contract}\n"\
        " during #{iterations} run(s) but got:\n#{stats}\n\n"\
        "For further investigations open: #{further_investigation}"
      end
    end

    def description
      "meet the contract:\n#{contract} \n"\
      " during #{iterations} run(s). Stats:\n#{stats}\n\n"\
      "For further investigations open: #{further_investigation}\n"
    end

    protected

    def valid?
      return if stopped_by_unexpected_behavior?
      contract.valid?
    end

    def further_investigation
      suite.storage.suggestion
    end

    def unexpected_further_investigation
      suite.storage.unexpected_suggestion
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

    def match_rules
      input = nil
      output = nil

      rules, options = contract.match do
        input = suite.data_generator.call
        output = checking_proc.call(input)
        [input, output, Hash.new]
      end

      suite.storage.save_run(options: options, rules: rules, context: context)

      rules
    rescue StandardError => e
      # FIXME: Possible recursion?
      # Write test about error in the yield (e.g. writing error)
      exception_options = {
        options: {
          input: input,
          output: output,
          meta: {exception: e},
        },
        rules: [Storage::EXCEPTION_CAUGHT],
        context: context,
      }
      suite.storage.save_run(exception_options)
      raise
    end
  end
end
