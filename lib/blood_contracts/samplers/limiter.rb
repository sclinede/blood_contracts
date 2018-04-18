module BloodContracts
  module Samplers
    class Limiter
      extend Dry::Initializer

      param :contract_name
      param :storage

      def limit_reached?(rule)
        tags = Hashie.symbolize_keys!(BloodContracts.tags[contract_name])
        rule = rule.to_sym
        rules_or_tags = Array(tags[rule] || rule).map(&:to_sym)
        return unless (limit = limits.values_at(*rules_or_tags).compact.min)
        storage.samples_count(rule) >= limit
      end

      private

      def limits
        Hashie.symbolize_keys!(
          BloodContracts.sampling_config[:limit_per_tag].to_h
        )
      end
    end
  end
end
