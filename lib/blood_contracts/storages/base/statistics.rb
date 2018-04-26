module BloodContracts
  module Storages
    class Base
      class Statistics
        def delete_all
          nil
        end

        def delete_statistics(_period)
          nil
        end

        def increment(_rule, _period = statistics.current_period)
          nil
        end

        def filter(*_periods)
          {}
        end

        def total
          {}
        end
      end
    end
  end
end
