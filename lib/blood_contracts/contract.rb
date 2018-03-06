module BloodContracts
  class Contract
    extend Dry::Initializer
    param :contract_hash, ->(v) { Hashie::Mash.new(v) }
    param :stats

    def match
      options = Hashie::Mash.new(Hash[%i(input output meta).zip(yield)])

      rule_names = select_matched_rules!(options).keys

      if rule_names.empty?
        stats.store(Storage::UNDEFINED_RULE)
      else
        Array(rule_names).each(&stats.method(:store))
      end

      [rule_names, options]
    end

    def select_matched_rules!(options)
      contract_hash.select do |name, rule|
        rule_options = options.shallow_merge(meta: {})
        matched = rule.check.call(rule_options)
        options.meta.merge!(name.to_sym => rule_options.meta)
        matched
      end
    end

    def valid?
      return if stats.found_unexpected_behavior?

      last_stats_run = stats.run
      expectations.all? do |rule, check|
        percent = last_stats_run[rule.name]&.percent || 0.0
        check.call(percent, rule)
      end
    end

    def expectations
      @expectations ||= Hash[
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

    def to_s
      contract_hash.map do |name, rule|
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
