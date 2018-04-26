module BloodContracts
  module Storages
    class Redis < Base
      class Statistics < Base::Statistics
        attr_reader :base_storage, :statistics
        def initialize(base_storage, statistics)
          @base_storage = base_storage
          @statistics = statistics
        end

        ROOT_KEY = "blood_statistics".freeze

        def delete_all
          base_storage.storage = (base_storage.global_store[root] = nil)
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
          stats = storage.values_at(*periods)
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

        def storage
          base_storage.storage
        end

        def global_store
          base_storage.global_store
        end

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
