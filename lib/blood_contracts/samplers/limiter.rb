module BloodContracts
  module Samplers
    class Limiter
      extend Dry::Initializer

      param :contract_name
      param :storage

      def limit_reached?(contract, rule)
        rules_or_tags = Array(contract_tags[rule.to_sym] || rule).map(&:to_sym)
        return unless (limit = limits.values_at(*rules_or_tags).compact.min)
        occasions_count(contract, rule) >= limit
      end

      private

      require_relative '../statistics.rb'
      Statistics = ::BloodContracts::Statistics::Middleware

      def occasions_count(contract, rule)
        if BloodContracts.middleware.exists?(Statistics)
          contract.statistics.current[rule] - 1
        else
          storage.count(rule)
        end
      end

      def contract_tags
        @contract_tags ||=
          Hashie.symbolize_keys!(BloodContracts.tags[contract_name])
      end

      def limits
        Hashie.symbolize_keys!(
          BloodContracts.sampling_config[:limit_per_tag].to_h
        )
      end
    end
  end
end
