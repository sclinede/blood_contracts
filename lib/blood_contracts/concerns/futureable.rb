if defined?(Concurrent::Future)
  require "concurrent"

  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(context: self, suite: to_contract_suite)
        end

        def runner
          return super if debug_enabled?
          @runner ||= RunnerFuture.new(_runner)
        end

        class RunnerFuture
          def initialize(runner)
            @runner = runner
          end

          def call(**kwargs)
            Concurrent::Future.execute { @runner.call(**kwargs) }
          end
        end
      end
    end
  end
end
