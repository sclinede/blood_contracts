module BloodContracts
  class Statistics
    extend Dry::Initializer
    param :iterations
    option :stats, default: -> { Hash.new(0) }

    def store(rule)
      stats[rule] += 1
    end

    def run
      Hash[stats.map { |rule_name, times| [rule_name, rule_stats(times)] }]
    end

    def rule_stats(times)
      Hashie::Mash.new(times: times, percent: (times.to_f / iterations))
    end

    def to_s
      run.map do |name, occasions|
        " - '#{name}' happened #{occasions.times} time(s) "\
        "(#{(occasions.percent * 100).round(2)}% of the time)"
      end.join("; \n")
    end

    def found_unexpected_behavior?
      run.key?(Storage::UNDEFINED_RULE)
    end
  end
end
