require_relative "./dsl.rb"
require_relative "./run_builder.rb"

module BloodContracts
  class BaseContract
    using StringPathize
    extend DSL
    include RunBuilder

    def enable!
      Thread.current[to_s.pathize] = true
    end

    def disable!
      Thread.current[to_s.pathize] = false
    end

    def enabled?
      if Thread.current[to_s.pathize].nil?
        Thread.current[to_s.pathize] = BloodContracts.config.enabled
      end
      !!Thread.current[to_s.pathize]
    end

    def before_runner(args:, kwargs:, output:, error:, meta:); end

    def before_call(args:, kwargs:, meta:); end

    def call(*args, **kwargs)
      return yield unless enabled?

      output = ""
      meta = {}
      error = nil
      before_call(args: args, kwargs: kwargs, meta: meta)

      begin
        output = yield(meta)
      rescue StandardError => exception
        error = exception
        raise error
      ensure
        before_runner(
          args: args, kwargs: kwargs, output: output, meta: meta, error: error
        )
        runner.call(
          args: args, kwargs: kwargs, output: output, meta: meta, error: error
        )
      end
    end
  end
end
