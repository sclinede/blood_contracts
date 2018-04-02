if defined?(Concurrent::Future)
  require "concurrent"

  # FIXME: doesn't work in Testing. Runner should have statistics
  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(context: self, suite: to_contract_suite)
        end

        def runner
          @runner ||= RunnerFuture.new(_runner)
        end

        class RunnerFuture
          def initialize(runner)
            @runner = runner
          end

          def call(**kwargs)
            Concurrent::Future.execute { @runner.call(**kwargs) }
          end

          def statistics
            @runner.statistics
          end
        end
      end
    end
  end
end
