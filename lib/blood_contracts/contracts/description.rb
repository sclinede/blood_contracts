module BloodContracts
  module Contracts
    class Description
      class << self
        def call(contract_hash)
          # TODO: guarantees
          Hashie::Mash.new(contract_hash)[:expectations].map do |name, rule|
            is_between = rule.threshold && rule.limit
            next(between_description(name, rule)) if is_between
            next(threshold_description(name, rule)) if rule.threshold
            next(limit_description(rule)) if rule.limit
            " - '#{name}' in any number of cases;"
          end.compact.join("\n")
        end

        private

        def between_description(name, rule)
          threshold = (rule.threshold * 100).round(2)
          limit = (rule.limit * 100).round(2)
          " - '#{name}' in more then #{threshold}% and"\
          " in less then #{limit} of cases;"
        end

        def limit_description(name, rule)
          " - '#{name}' in less then #{(rule.limit * 100).round(2)}% of cases;"
        end

        def threshold_description(name, rule)
          percentage = (rule.threshold * 100).round(2)
          " - '#{name}' in more then #{percentage}% of cases;"
        end
      end
    end
  end
end
