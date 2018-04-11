if defined?(Concurrent::Future)
  require "concurrent"

  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(
            context: self, contract: _contract, storage: storage
          )
        end

        def runner
          @runner ||=
            respond_to?(:testing?) ? _runner : RunnerFuture.new(_runner)
        end

        class RunnerFuture < SimpleDelegator
          def call(**kwargs)
            Concurrent::Future.execute { __getobj__.call(**kwargs) }
          end
        end
      end
    end
  end
end
