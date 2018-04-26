module BloodContracts
  module Storages
    class Dummy < Base
      def delete_all_statistics
        global_store[statistics_root] = nil
        @storage = global_store[statistics_root]
      end

      def delete_statistics(period)
        storage.fetch(period)
        storage[period] = nil
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
          Time.at(period_int * statistics.period_size)
        end
        Hash[periods.zip(stats)]
      end

      def total_statistics
        Hash[
          storage.sort_by { |(period_int, _)| -period_int }.map do |k, v|
            [Time.at(k * statistics.period_size), v]
          end
        ]
      end

      def samples_count(_rule, _period = current_period)
        0
      end

      def find_all_samples(_path = nil, **_kwargs)
        []
      end

      def find_sample(_path = nil, **_kwargs)
        nil
      end

      def sample_exists?(_sample_name)
        false
      end
    end
  end
end
