require_relative "round"
require_relative "runners/matcher"
require_relative "contracts/description"

module BloodContracts
  class Runner
    extend Dry::Initializer

    param :contract
    option :context, optional: true

    def call(**kwargs)
      round_data = apply_defaults!(kwargs)
      round_data.merge!(pack_yielded_result(yield(meta))) if block_given?
      matcher.call(Round.new(round_data)) do |rules, round|
        BloodContracts.middleware.invoke(contract, round, rules, context)
      end
    end

    protected

    def pack_yielded_result(yielded_result)
      Hash[
        %i(output meta error).zip(yielded_result)
      ]
    end

    def apply_defaults!(kwargs)
      kwargs[:input] = {
        args: kwargs.fetch(:args),
        kwargs: kwargs.fetch(:kwargs)
      }
      kwargs[:output] = kwargs.fetch(:output) { "" }
      kwargs[:meta]   = kwargs.fetch(:meta) { {} }
      kwargs[:error]  = kwargs.fetch(:error) { nil }
      kwargs
    end

    def matcher
      Runners::Matcher.new(contract.to_h)
    end
  end
end
