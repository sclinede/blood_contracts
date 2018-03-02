module BloodContracts
  class Runner
    extend Dry::Initializer

    param :checking_proc
    option :context, optional: true

    option :suite

    option :iterations, ->(v) do
      v = ENV["iterations"] if ENV["iterations"]
      v.to_i.positive? ? v.to_i : 1
    end, default: -> { 1 }

    option :time_to_run, ->(v) do
      v = ENV["duration"] if ENV["duration"]
      v.to_f if v.to_f.positive?
    end, optional: true

    option :stop_on_unexpected, default: -> { false }

    option :stats, default: -> { Hash.new(0) }

    def call
      return true if debug_mode? && !debugging_sample?

      iterate do
        unexpected = match_rules(*run) do |input, output, rules|
          suite.storage.save_run(
            input: input, output: output, rules: rules, context: context,
          )
        end.empty?
        throw :unexpected_behavior, :stop if stop_on_unexpected && unexpected
      end
      valid?
    end

    def valid?
      return if stopped_by_unexpected_behavior?
      return if found_unexpected_behavior?

      last_run_stats = run_stats
      expectations_checks.all? do |rule, check|
        percent = last_run_stats[rule.name]&.percent || 0.0
        check.call(percent, rule)
      end
    end

    def found_unexpected_behavior?
      run_stats.key?(Storage::UNDEFINED_RULE)
    end

    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if found_unexpected_behavior?
        "#{intro}\n#{contract_description}\n"\
        " during #{iterations} run(s) but got unexpected behavior.\n\n"\
        "For further investigations open: #{unexpected_behavior_report_path}/"
      else
        "#{intro}\n#{contract_description}\n"\
        " during #{iterations} run(s) but got:\n#{stats_description}\n\n"\
        "For further investigations open: #{suite.storage.suggestion}"
      end
    end

    def unexpected_behavior_report_path
      File.join(suite.storage.suggestion, Storage::UNDEFINED_RULE.to_s)
    end

    def description
      return "skipped in debugging" if debug_mode? && !debugging_sample?

      "meet the contract:\n#{contract_description} \n"\
      " during #{iterations} run(s). Stats:\n#{stats_description}\n\n"\
      "For further investigations open: #{suite.storage.suggestion}\n"
    end

    private

    def debug_mode?
      return @debug_mode if defined? @debug_mode
      @debug_mode = ENV["debug"].present?
    end

    def debugging_sample?
      return @debugging_sample if defined? @debugging_sample
      @debugging_sample =
        debug_mode? && suite.storage.run_exists?(ENV["debug"])
    end

    def run
      return debugging_run if debugging_sample?

      input = suite.data_generator.call
      [input, checking_proc.call(input)]
    end

    def debugging_run
      run_pattern = ENV["debug"]
      suite.storage.load_run(run_pattern)
    end

    def stopped_by_unexpected_behavior?
      @_stopped_by_unexpected_behavior == :stop
    end

    def iterate
      run_iterations = 1 if debugging_sample?
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

    def match_rules(input, output)
      matched_rules = suite.contract.select do |_name, rule|
        rule.check.call(input, output)
      end.keys
      matched_rules = [Storage::UNDEFINED_RULE] if matched_rules.empty?
      Array(matched_rules).each { |rule| stats[rule] += 1 }

      yield(input, output, matched_rules) unless debugging_sample?

      matched_rules
      # FIXME: Possible recursion?
      # Write test about error in the yield (e.g. writing error)
    rescue StandardError => e
      yield [Storage::UNDEFINED_RULE]
      raise e
    end

    def threshold_check(value, rule)
      value > rule.threshold
    end

    def limit_check(value, rule)
      value <= rule.limit
    end

    def expectations_checks
      Hash[
        suite.contract.map do |name, rule|
          if rule.threshold
            [rule.merge(name: name), method(:threshold_check)]
          elsif rule.limit
            [rule.merge(name: name), method(:limit_check)]
          end
        end.compact
      ]
    end

    def contract_description
      suite.contract.map do |name, rule|
        rule_description = " - '#{name}' "
        if rule.threshold
          rule_description << <<~TEXT
            in more then #{(rule.threshold * 100).round(2)}% of cases;
          TEXT
        elsif rule.limit
          rule_description << <<~TEXT
            in less then #{(rule.limit * 100).round(2)}% of cases;
          TEXT
        else
          next
        end
        rule_description
      end.compact.join
    end

    def stats_description
      run_stats.map do |name, occasions|
        " - '#{name}' happened #{occasions.times} time(s) "\
        "(#{(occasions.percent * 100).round(2)}% of the time)"
      end.join("; \n")
    end

    def run_stats
      Hash[
        stats.map do |rule_name, times|
          [
            rule_name,
            Hashie::Mash.new(
              times: times,
              percent: (times.to_f / iterations),
            ),
          ]
        end
      ]
    end
  end
end
