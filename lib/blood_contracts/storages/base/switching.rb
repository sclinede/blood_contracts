module BloodContracts
  module Storages
    class Base
      class Switching
        def enable_all!
          raise ArgumentError, <<~MESSAGE
            Global "hot" enable for contracts is not supported.
            Please, use configuration setting or another storage backend.
          MESSAGE
        end

        def disable_all!
          raise ArgumentError, <<~MESSAGE
            Global "hot" disable for contracts is not supported.
            Please, use configuration setting or another storage backend.
          MESSAGE
        end

        def enable!(*)
          false
        end

        def disable!(*)
          false
        end

        def enabled?(*)
          BloodContracts.config.enabled
        end
      end
    end
  end
end
