require_relative "contracts/dsl.rb"
require_relative "contracts/patching.rb"
require_relative "contracts/switching.rb"
require_relative "contracts/status.rb"
require_relative "contracts/toolbox.rb"

module BloodContracts
  class BaseContract
    using StringCamelize
    extend Contracts::DSL
    extend Contracts::Patching
    include Contracts::Toolbox
    include Contracts::Switching

    def initialize
      reset_contract_hash!
      reset_runner!
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

    attr_reader :_contract_hash
    alias :to_h :_contract_hash

    protected

    def before_call(args:, kwargs:, meta:); end

    def before_runner(args:, kwargs:, output:, error:, meta:); end
    alias :after_call :before_runner

    private

    attr_reader :runner
    def reset_runner!
      @runner = Runner.new(self, context: self)
    end

    def reset_contract_hash!
      guarantees = self.class.guarantees_rules.flat_map do |name|
        prepare_guarantee(name)
      end
      expectations = self.class.expectations_rules.flat_map do |rule_name|
        prepare_expectation(rule_name)
      end
      @_contract_hash = { guarantees: guarantees, expectations: expectations }
    end

    def constantize_rule(rule_name, prefix)
      self.class.const_get("#{prefix}_#{rule_name}".camelcase(:upper))
    end

    def prepare_guarantee(rule_name)
      constantize_rule(rule_name, "guarantee")
        .with_children
        .map do |rule, name|
        [rule.original_name, {check: rule}]
      end
    end

    def prepare_expectation(rule_name)
      constantize_rule(rule_name, "expectation")
        .with_children
        .map do |rule|
        name = rule.original_name
        stats_requirements = self.class.statistics_guarantees[name].to_h
        [name, stats_requirements.merge(check: rule)]
      end
    end
  end
end
