module BloodContracts
  module Storages
    class Dummy < Base
      def increment_statistics(_rule, _period = current_period)
        nil
      end

      def statistics_per_rule(*_rules)
        {}
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
