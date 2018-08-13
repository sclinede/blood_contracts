module BloodContracts
  module Samplers
    class Limiter
      extend Dry::Initializer

      param :contract_name
      param :storage

      attr_reader :offset
      def initialize(*)
        super
        recalibrate_stats_count_offset
      end

      def limit_reached?(contract, rule)
        rules_or_tags = Array(contract_tags[rule.to_sym] || rule).map(&:to_sym)
        return unless (limit = limits.values_at(*rules_or_tags).compact.min)
        occasions_count(contract, rule) >= limit
      end

      private

      def recalibrate_stats_count_offset
        stats_mw_index = BloodContracts.middleware.index_of(Statistics)
        return(@offset = nil) unless stats_mw_index
        sampler_mw_index = BloodContracts.middleware.index_of(Sampler)
        @offset = sampler_mw_index > stats_mw_index ? -1 : 0
      end

      require_relative '../statistics.rb'
      Statistics = ::BloodContracts::Statistics::Middleware
      Sampler = ::BloodContracts::Sampler::Middleware

      def fallback_to_statistics?
        !!@offset
      end

      def occasions_count(contract, rule)
        if fallback_to_statistics?
          contract.statistics.current[rule].to_i + offset
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
