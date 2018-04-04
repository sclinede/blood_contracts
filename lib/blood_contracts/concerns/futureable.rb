if defined?(Concurrent::Future)
  require "concurrent"

  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(context: self, suite: to_contract_suite)
        end

        def runner
          @runner ||=
            respond_to?(:testing?) ? _runner : RunnerFuture.new(_runner)
        end

        class RunnerFuture < SimpleDelegator
          def call(**kwargs)
            Concurrent::Future.execute { __get_obj__.call(**kwargs) }
          end
        end
      end
    end
  end
end
