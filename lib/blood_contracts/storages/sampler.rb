module BloodContracts
  module Storages
    class Sampler
      extend Dry::Initializer

      param :contract_name
      param :backend

      def limit_reached?(rule)
        priorities = BloodContracts.config.priorities[contract_name]
        rule_priority = priorities[rule].to_s
        return unless limits.fetch(rule_priority) { false }
        backend.samples_count(rule) >= limits[rule_priority]
      end

      private

      def limits
        BloodContracts.config.sampling_limits.to_h
      end
    end
  end
end
