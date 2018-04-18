require_relative "../runners/iterator.rb"

module BloodContracts
  module Contracts
    module Debuggable
      using StringPathize

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
        @runner =
          Debugger.new(
            context: self, contract: _contract,
            storage: storage, statistics: statistics
          )
      end
      alias :debug_runner :runner

      def warn_about_reraise_on(error)
        error ||= {}
        raise error unless error.respond_to?(:to_hash)
        warn(<<~TEXT) unless error.empty?
          Skipped raise of #{error.keys.first} while debugging
        TEXT
      end

      Iterator = ::BloodContracts::Runners::Iterator

      def call(*args, **kwargs)
        return super unless debug_enabled?

        output = nil
        iterator = Iterator.new(debug_runner.iterations)
        iterator.next do
          round = debug_runner.call
          warn_about_reraise_on(round.error)
        end
        output
      end
    end
  end
end
