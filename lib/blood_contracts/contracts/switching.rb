module BloodContracts
  module Contracts
    module Switching
      using StringPathize

      def enable!
        Thread.current[name] = true
      end

      def disable!
        Thread.current[name] = false
      end

      def reset!
        Thread.current[name] = nil
      end

      def enabled?
        Thread.current[name] = switcher.enabled? if Thread.current[name].nil?
        !!Thread.current[name]
      end

      private

      def name
        to_s.pathize
      end
    end
  end
end
