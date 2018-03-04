module BloodContracts
  class Contract
    extend Dry::Initializer
    param :contract_hash, ->(v) { Hashie::Mash.new(v) }
    param :iterations
    param :stats

    def valid?
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

    def expectations
      @description ||= Hash[
        contract_hash.map do |name, rule|
          if rule.threshold
            [rule.merge(name: name), method(:threshold_check)]
          elsif rule.limit
            [rule.merge(name: name), method(:limit_check)]
          else
            [rule.merge(name: name), method(:anyway)]
          end
        end.compact
      ]
    end

    def description
      @description ||= contract_hash.map do |name, rule|
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
          rule_description << <<~TEXT
            in any number of cases;
          TEXT
        end
        rule_description
      end.compact.join
    end

    def run_stats
      Hash[stats.map { |rule_name, times| [rule_name, rule_stats(times)] }]
    end

    def rule_stats(times)
      Hashie::Mash.new(times: times, percent: (times.to_f / iterations))
    end

    def run_stats_description
      run_stats.map do |name, occasions|
        " - '#{name}' happened #{occasions.times} time(s) "\
        "(#{(occasions.percent * 100).round(2)}% of the time)"
      end.join("; \n")
    end

    private

    def threshold_check(value, rule)
      value > rule.threshold
    end

    def limit_check(value, rule)
      value <= rule.limit
    end

    def anyway(value, rule)
      true
    end
  end
end
