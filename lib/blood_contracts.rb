require "blood_contracts/version"
require_relative "blood_contracts/suite"
require_relative "blood_contracts/storage"
require_relative "blood_contracts/runner"

module BloodContracts

  # Use https://github.com/razum2um/lurker/blob/master/lib/lurker/spec_helper/rspec.rb
  if defined?(RSpec) && RSpec.respond_to?(:configure)
    module MeetContractMatcher
      extend RSpec::Matchers::DSL

      matcher :meet_contract_rules do |options|
        match do |actual|
          raise ArgumentError unless actual.respond_to?(:call)

          @_contract_runner = Runner.new(
            actual,
            context: self,
            suite: build_suite(options),
            iterations: @_iterations,
            time_to_run: @_time_to_run,
            stop_on_unexpected: @_halt_on_unexpected,
          )
          @_contract_runner.call
        end

        def build_suite(options)
          suite = options[:contract_suite] || Suite.new

          suite.data_generator = @_generator        if @_generator
          suite.contract       = options[:contract] if options[:contract]
          suite.input_writer   = _input_writer      if _input_writer
          suite.output_writer  = _output_writer     if _output_writer

          suite
        end

        def _input_writer
          input_writer = @_writers.to_h[:input]
          input_writer ||= :input_writer if defined? self.input_writer
          input_writer
        end

        def _output_writer
          output_writer = @_writers.to_h[:output]
          output_writer ||= :output_writer if defined? self.output_writer
          output_writer
        end

        supports_block_expectations

        failure_message { @_contract_runner.failure_message }

        description { @_contract_runner.description }

        chain :using_generator do |generator|
          if generator.respond_to?(:to_sym)
            @_generator = method(generator.to_sym)
          else
            fail ArgumentError unless generator.respond_to?(:call)
            @_generator = generator
          end
        end

        chain :during_n_iterations_run do |iterations|
          @_iterations = Integer(iterations)
        end

        chain :during_n_seconds_run do |time_to_run|
          @_time_to_run = Float(time_to_run)
        end

        chain :halt_on_unexpected do
          @_halt_on_unexpected = true
        end

      end
    end
  end
end
