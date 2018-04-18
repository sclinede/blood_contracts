module BloodContracts
  module Storages
    class Memory < Base
      STATISTICS_ROOT_KEY = "blood_statistics".freeze

      attr_reader :storage
      def init
        return unless storage.nil?
        if global_store.nil?
          BloodContracts.instance_variable_set(
            :@memory_store, storage_klass.new
          )
        end
        global_store[statistics_root] = storage_klass.new
        @storage = global_store[statistics_root]
      end

      def increment_statistics(rule, period = statistics.current_period)
        prepare_statistics_storage(period)
        # FIXME: Concurrency - Lock! Lock! Lock!
        storage[period][rule] += 1
      end

      def period_statistics(period)
        storage.fetch(period)
      end

      def filtered_statistics(*periods)
        stats = storage.values_at(*periods)
        periods.map! do |period_int|
          Time.at(period_int * statistics.configured_period)
        end
        Hash[periods.zip(stats)]
      end

      def total_statistics
        Hash[
          storage.sort_by { |(period_int, _)| -period_int }
        ].transform_keys do |period_int|
          Time.at(period_int * statistics.configured_period)
        end
      end

      private

      def storage_klass
        @storage_klass ||= if defined?(::Concurrent::Map)
                             ::Concurrent::Map
                           else
                             ::Hash
                           end
      end

      def global_store
        BloodContracts.instance_variable_get(:@memory_store)
      end

      def storage
        @storage ||= global_store.to_h[contract_name]
      end

      def prepare_statistics_storage(period)
        return unless storage[period].nil?
        storage[period] = storage_klass.new { 0 }
      end

      # TODO: do we need `session` here?
      def statistics_root
        "#{STATISTICS_ROOT_KEY}-#{contract_name}"
      end
    end
  end
end
