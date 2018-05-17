module BloodContracts
  module Storages
    class Memory < Base
      class Statistics
        ROOT_KEY = "blood_stats".freeze

        attr_reader :global_store, :contract_name, :storage_klass, :statistics
        def initialize(base_storage, statistics)
          @global_store = base_storage.global_store
          @contract_name = base_storage.contract_name
          @storage_klass = base_storage.storage_klass
          @statistics = statistics
        end

        attr_reader :storage
        def init
          @storage = global_store[root]
          return @storage unless @storage.nil?
          global_store[root] = storage_klass.new
          @storage = global_store[root]
        end

        def delete_all
          @storage = (global_store[root] = nil)
        end

        def delete(period)
          storage.fetch(period)
          storage[period] = nil
        end

        def increment(rule, period = statistics.current_period)
          prepare_storage(period)
          # FIXME: Concurrency - Lock! Lock! Lock!
          storage[period][rule] += 1
        end

        def filter(*periods)
          # FIXME: #values_at not exist for Concurrent::Map
          # stats = storage.values_at(*periods)
          stats = periods.each_with_object([]) do |period, data|
            next unless (period_data = storage[period])
            data << Hash[period_data.keys.zip(period_data.values)]
          end
          periods.map! do |period_int|
            Time.at(period_int * statistics.period_size)
          end
          Hash[periods.zip(stats)]
        end

        def total
          Hash[
            storage.sort_by { |(period_int, _)| -period_int }.map do |k, v|
              [Time.at(k * statistics.period_size), v]
            end
          ]
        end

        private

        def prepare_storage(period)
          return unless storage[period].nil?
          storage[period] = storage_klass.new { 0 }
        end

        # TODO: do we need `session` here?
        def root
          "#{ROOT_KEY}-#{contract_name}"
        end
      end
    end
  end
end
