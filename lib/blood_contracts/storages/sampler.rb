module BloodContracts
  module Storages
    class Sampler
      extend Dry::Initializer

      param :contract_name
      param :backend

      def limit_reached?(rule)
        tags = BloodContracts.config.tags[contract_name]
        rule_or_tag = (tags[rule] || rule).to_sym
        return unless limits.fetch(rule_or_tag) { false }
        backend.samples_count(rule) >= limits[rule_or_tag]
      end

      private

      def limits
        BloodContracts.sampling_config[:limit_per_tag].to_h
      end
    end
  end
end
