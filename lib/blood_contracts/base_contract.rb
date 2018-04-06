require_relative "./dsl.rb"
require_relative "./storage_builder.rb"

module BloodContracts
  class BaseContract
    using StringPathize
    extend DSL
    include StorageBuilder

    def enable!
      Thread.current[name] = true
    end

    def disable!
      Thread.current[name] = false
    end

    def reset!
      Thread.current[name] = nil
    end

    def enabled?
      if Thread.current[name].nil?
        Thread.current[name] = storage.contract_enabled?
      end
      !!Thread.current[name]
    end

    def to_contract_suite
      Suite.new(storage: storage, contract: _contract)
    end

    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

    protected

    def before_call(args:, kwargs:, meta:); end

    def before_runner(args:, kwargs:, output:, error:, meta:); end
    alias :after_call :before_runner

    private

    def runner
      @runner ||= Runner.new(context: self, suite: to_contract_suite)
    end

    def _contract
      @_contract ||= Hash[
        self.class.rules.map { |name| [name, { check: method("_#{name}") }] }
      ]
    end

    def name
      to_s.pathize
    end
  end
end
