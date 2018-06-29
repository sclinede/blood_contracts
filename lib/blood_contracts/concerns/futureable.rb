if defined?(Concurrent::Future)
  warn "EXPERIMENTAL. BloodContracts::Concerns::Futureable is experimental and"\
       "could cause unexpected behavior if your code is not Thread-safe"
  require "concurrent"

  module BloodContracts
    module Concerns
      module Futureable
        def _runner
          @_runner ||= Runner.new(self, context: self)
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
else
  warn "You're attempted to use Futureable, but Concurrent::Future class is "\
       "not registered yet. Please, install `concurrent-ruby` gem."
end
