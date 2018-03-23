module BloodContracts
  module Concerns
    module Debuggable
      def enable_debug!
        Thread.current["#{to_s.pathize}_debug"] = true
      end

      def disable_debug!
        Thread.current["#{to_s.pathize}_debug"] = false
        @runner = nil
        runner
        debug_enabled?
      end

      def debug_enabled?
        !!Thread.current["#{to_s.pathize}_debug"]
      end

      def runner
        return super unless debug_enabled?
        return @runner if @runner.is_a?(Debugger)
        @runner = Debugger.new(context: self, suite: to_contract_suite)
      end
    end
  end
end