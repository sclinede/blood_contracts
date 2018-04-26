module BloodContracts
  module Samplers
    class Limiter
      extend Dry::Initializer

      param :contract_name
      param :storage

      def limit_reached?(rule)
        rules_or_tags = Array(contract_tags[rule.to_sym] || rule).map(&:to_sym)
        return unless (limit = limits.values_at(*rules_or_tags).compact.min)
        storage.count(rule) >= limit
      end

      private

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
