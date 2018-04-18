module BloodContracts
  module Storages
    class Dummy < Base
      def increment_statistics(rule, period = current_period)
        nil
      end

      def statistics_per_rule(*rules)
        Hash.new
      end

      def samples_count(rule, period = current_period)
        0
      end

      def find_all_samples(path = nil, **kwargs)
        Array.new
      end

      def find_sample(path = nil, **kwargs)
        nil
      end

      def sample_exists?(sample_name)
        false
      end
    end
  end
end
