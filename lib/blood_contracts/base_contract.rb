require_relative "contracts/dsl.rb"
require_relative "contracts/patching.rb"
require_relative "contracts/switching.rb"
require_relative "contracts/toolbox.rb"

module BloodContracts
  class BaseContract
    extend Contracts::DSL
    extend Contracts::Patching
    include Contracts::Toolbox
    include Contracts::Switching

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
        context: self, contract: _contract,
        sampler: sampler, statistics: statistics
      )
    end

    def _contract
      return @_contract if defined? @_contract
      guarantees = self.class.guarantees_rules.map do |name|
        [name, { check: method("guarantee_#{name}") }]
      end
      expectations = self.class.expectations_rules.map do |name|
        stats_requirements = self.class.statistics_rules[name].to_h
        [name, stats_requirements.merge(check: method("expectation_#{name}"))]
      end
      @_contract = { guarantees: guarantees, expectations: expectations }
    end
  end
end
