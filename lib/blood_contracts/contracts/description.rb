module BloodContracts
  module Contracts
    class Description
      class << self
        def call(contract_hash)
          Hashie::Mash.new(contract_hash).map do |name, rule|
            next(threshold_description(name, rule)) if rule.threshold
            next(limit_description(rule)) if rule.limit
            " - '#{name}' in any number of cases;"
          end.compact.join
        end

        private

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
