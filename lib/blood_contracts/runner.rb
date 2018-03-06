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

    def run
      input = suite.data_generator.call
      [input, checking_proc.call(input)]
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
      input, output = run
      matched_rules = suite.contract.select do |_name, rule|
        rule.check.call(input, output)
      end.keys

      matched_rules = [Storage::UNDEFINED_RULE] if matched_rules.empty?

      Array(matched_rules).each(&stats.method(:store))

      process_match(input, output, matched_rules)

      matched_rules
    rescue StandardError
      # FIXME: Possible recursion?
      # Write test about error in the yield (e.g. writing error)
      process_match(input, output, [Storage::EXCEPTION_CAUGHT])
      raise
    end

    def process_match(input, output, rules)
      suite.storage.save_run(
        input: input, output: output, rules: rules, context: context,
      )
    end
  end
end
