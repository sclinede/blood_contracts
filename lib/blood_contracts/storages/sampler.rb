module BloodContracts
  module Storages
    class Sampler
      extend Dry::Initializer

      param :contract_name
      param :backend

      def limit_reached?(rule)
        tags = BloodContracts.config.tags[contract_name]
        rule_tag = tags[rule].to_s
        return unless limits.fetch(rule_tag) { false }
        backend.samples_count(rule) >= limits[rule_tag]
      end

      private

      def limits
        BloodContracts.config.sampling["limits_per_tag"].to_h
      end
    end
  end
end
