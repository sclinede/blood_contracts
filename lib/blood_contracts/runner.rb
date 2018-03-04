module BloodContracts
  class Runner < BaseRunner
    extend Dry::Initializer

    option :iterations, ->(v) do
      v = ENV["iterations"] if ENV["iterations"]
      v.to_i.positive? ? v.to_i : 1
    end, default: -> { 1 }
    option :time_to_run, ->(v) do
      v = ENV["duration"] if ENV["duration"]
      v.to_f if v.to_f.positive?
    end, optional: true

    def process_match(input, output, rules)
      suite.storage.save_run(
        input: input, output: output, rules: rules, context: context,
      )
    end

    private

    def run
      input = suite.data_generator.call
      [input, checking_proc.call(input)]
    end
  end
end
