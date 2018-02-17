module BloodContracts
  class Runner
    extend Dry::Initializer

    param :checking_proc
    option :context, optional: true

    option :suite

    option :iterations,
           ->(v) { v.to_i.positive? ? v.to_i : 1 },
           default: -> { 1 }

    option :time_to_run,
           ->(v) { v.to_f if v.to_f.positive? },
           optional: true

    option :stop_on_unexpected, default: false

    def call
      iterate do
        unexpected = match_rules(input, output) do |rules|
          suite.storage.save_run(
            input: input, output: output, rules: rules, context: context,
          )
        end.empty?
        throw :unexpected_behavior, :found if stop_on_unexpected && unexpected
      end
      valid?
    end

    def valid?
      return if found_unexpected_behavior?

      run_stats = running_stats
      expectations_checks.all? do |rule, check|
        percent = run_stats[rule.name]&.percent || 0.0
        check.call(percent, rule)
      end
    end

    def match_and_store(input, output)
      matched_rules = match_rules(input, output) do |rules|
        suite.storage.save_run(
          input: input,
          output: output,
          rules: rules,
          context: context,
        )
      end

      throw :unexpected_behavior, :found if matched_rules.empty?
    end

    def failure_message
      intro = "expected that given Proc would meet the contract:"

      if found_unexpected_behavior?
        "#{intro}\n#{contract_description}\n"\
        " during #{iterations} run(s) but got unexpected behavior.\n"\
        "For further investigations open:"\
        " file://#{unexpected_behavior_report_path}"
      else
        "#{intro}\n#{contract_description}\n"\
        " during #{iterations} run(s) but got:\n#{stats_description}\n"
      end
    end

    def unexpected_behavior_report_path
      File.join(suite.storage.root, Storage::UNDEFINED_RULE.to_s)
    end

    def description
      "meet the contract:\n#{contract_description} \n"\
        " during #{iterations} run(s). Run(s) stats:\n#{stats_description}"
    end

    private

    def run
      input = suite.data_generator.call
      [input, checking_proc.call(input)]
    end

    def found_unexpected_behavior?
      @_found_unexpected_behavior == :found
    end

    def stats
      suite.storage.stats
    end

    def iterate
      run_iterations = iterations

      if time_to_run
        run_iterations = iterations_count_from_time_to_run { yield }
        @iterations = run_iterations + 1
      end

      @_found_unexpected_behavior = catch(:unexpected_behavior) do
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

      yield matched_rules.empty? ? [Storage::UNDEFINED_RULE] : matched_rules

      matched_rules
      # FIXME: Possible recursion?
      # Write test about error in the yield (e.g. writing error)
    rescue => e
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
          else
            nil
          end
        end.compact
      ]
    end

    def contract_description
      suite.contract.map do |name, rule|
        rule_description = " - '#{name}'"
        if rule.threshold
          rule_description << <<~TEXT
            in more then #{rule.threshold * 100}% of cases;
          TEXT
        elsif rule.limit
          rule_description << <<~TEXT
            in less then #{rule.limit * 100}% of cases;
          TEXT
        else
          next
        end
        rule_description
      end.compact.join
    end

    def stats_description
      running_stats.map do |name, occasions|
        " - '#{name}' happened #{occasions.count} time(s) "\
        "(#{occasions.percent * 100}% of the time)"
      end.join("; \n")
    end

    def running_stats
      Hash[
        stats.map do |rule_name, count|
          [
            rule_name,
            Hashie::Mash.new(
              count: count,
              percent: (count.to_f / iterations).round(2),
            ),
          ]
        end
      ]
    end
  end
end
