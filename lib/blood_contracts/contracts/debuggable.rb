module BloodContracts
  module Contracts
    module Debuggable
      using StringPathize

      def enable_debug!
        Thread.current["#{to_s.pathize}_debug"] = true
      end

      def disable_debug!
        Thread.current["#{to_s.pathize}_debug"] = false
        debug_enabled?
      end

      def debug_enabled?
        !!Thread.current["#{to_s.pathize}_debug"] || !!ENV["DEBUG_CONTRACTS"]
      end

      def debugger
        return super unless debug_enabled?
        @debugger ||= Debugger.new(
          context: self, contract: _contract,
          storage: storage, statistics: statistics
        )
      end

      def warn_about_reraise_on(error)
        error ||= {}
        raise error unless error.respond_to?(:to_hash)
        warn(<<~TEXT) unless error.empty?
          Skipped raise of #{error.keys.first} while debugging
        TEXT
      end

      # rubocop:disable Lint/Debugger
      def call(*args, **kwargs)
        return super unless debug_enabled?

        output = nil
        debugger.iterations.times do
          round = debugger.call
          warn_about_reraise_on(round.error)
        end
        output
      end
      # rubocop:enable Lint/Debugger
    end
  end
end
