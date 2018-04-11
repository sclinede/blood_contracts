require_relative "./dsl.rb"
require_relative "./patching.rb"
require_relative "./switching.rb"
require_relative "./storage_builder.rb"

module BloodContracts
  class BaseContract
    extend DSL
    extend Patching
    include StorageBuilder
    include Switching


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
      @runner ||= Runner.new(
        context: self, contract: _contract, storage: storage
      )
    end

    def _contract
      @_contract ||= Hash[
        self.class.rules.map do |name|
          stats_requirements = self.class.statistics_rules[name].to_h
          [name, stats_requirements.merge(check: method("_#{name}"))]
        end
      ]
    end
  end
end
