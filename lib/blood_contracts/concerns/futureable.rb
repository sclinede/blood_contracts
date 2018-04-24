if defined?(Concurrent::Future)
  require "concurrent"

  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(
            context: self, contract: _contract,
            sampler: sampler, statistics: statistics
          )
        end

        def runner
          @runner ||= RunnerFuture.new(_runner)
        end

        # FIXME: track errors in the execution
        class RunnerFuture < SimpleDelegator
          def call(**kwargs)
            Concurrent::Future.execute { __getobj__.call(**kwargs) }
          end
        end
      end
    end
  end
end
