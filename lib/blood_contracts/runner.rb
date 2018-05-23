require_relative "round"
require_relative "runners/matcher"
require_relative "contracts/description"

module BloodContracts
  class Runner
    extend Dry::Initializer

    param :contract
    option :context, optional: true

    # FIXME: block argument is not under tracking.
    def call(args:, kwargs:, output: "", meta: {}, error: nil)
      (output, meta, error = yield(meta)) if block_given?
      round = Round.new(
        input: { args: args, kwargs: kwargs },
        output: output, error: error, meta: meta
      )
      matcher.call(round) do |rules|
        BloodContracts.middleware.invoke(contract, round, rules, context)
      end
    end

    protected

    def matcher
      Runners::Matcher.new(contract.to_h)
    end
  end
end
