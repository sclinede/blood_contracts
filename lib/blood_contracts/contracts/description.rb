module BloodContracts
  module Contracts
    class Description
      def self.call(contract_hash)
        Hashie::Mash.new(contract_hash).map do |name, rule|
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
    end
  end
end
