module BloodContracts
  module Concerns
    module Debuggable
      using StringExtensions

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
        !!Thread.current["#{to_s.pathize}_debug"] || !!ENV["DEBUG_CONTRACTS"]
      end

      def runner
        return super unless debug_enabled?
        return @runner if @runner.is_a?(Debugger)
        @runner = Debugger.new(context: self, suite: to_contract_suite)
      end
      alias :debugger :runner

      def warn_about_reraise_on(error)
        error ||= {}
        raise error unless error.respond_to?(:to_hash)
        warn(<<~TEXT) unless error.empty?
          Skipped raise of #{error.keys.first} while debugging
        TEXT
      end

      Iterator = ::BloodContracts::Contracts::Iterator

      def call(*args, **kwargs)
        return super unless debug_enabled?

        output = nil
        iterator = Iterator.new(debugger.iterations)
        debugger.statistics.iterations_count = iterator.count

        iterator.next do
          data = debugger.call
          error = data.last
          warn_about_reraise_on(error)
        end
        output
      end
    end
  end
end
