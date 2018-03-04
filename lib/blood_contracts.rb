require "blood_contracts/version"
require_relative "blood_contracts/suite"
require_relative "blood_contracts/storage"
require_relative "blood_contracts/base_runner"
require_relative "blood_contracts/runner"
require_relative "blood_contracts/debugger"
require_relative "blood_contracts/base_contract"

module BloodContracts
  # Use https://github.com/razum2um/lurker/blob/master/lib/lurker/spec_helper/rspec.rb
  if defined?(RSpec) && RSpec.respond_to?(:configure)
    module MeetContractMatcher
      extend RSpec::Matchers::DSL

      matcher :meet_contract_rules do |args|
        match do |subject|
          raise ArgumentError unless valid_subject?(subject)
          runner = ENV["debug"] ? Debugger : Runner

          @_contract_runner = runner.new(
            actual,
            context: self,
            suite: build_suite(args || subject),
            iterations: @_iterations,
            time_to_run: @_time_to_run,
            stop_on_unexpected: @_halt_on_unexpected,
          )
          @_contract_runner.call
        end

        def build_suite(args)
          if args.respond_to?(:to_contract_suite)
            suite = args.to_contract_suite(name: _example_name_to_path)
          elsif args.respond_to?(:to_hash)
            suite = Suite.new(storage: new_storage)
            suite.contract       = options[:contract] if options[:contract]
          end
          suite.data_generator = @_generator if @_generator
          suite
        end

        def valid_subject?(subject)
          subject.respond_to?(:call) || subject.respond_to?(:to_contract_suite)
        end

        def new_storage
          storage = Storage.new(example_name: _example_name_to_path)
          storage.input_writer  = _input_writer  if _input_writer
          storage.output_writer = _output_writer if _output_writer
          storage.input_serializer  = @_input_serializer
          storage.output_serializer = @_output_serializer
          storage
        end

        def _example_name_to_path
          method_missing(:class)
            .name
            .sub("RSpec::ExampleGroups::", "")
            .snakecase
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
            raise ArgumentError unless generator.respond_to?(:call)
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

        chain :serialize_input do |serializer|
          @_input_serializer = serializer
        end

        chain :serialize_output do |serializer|
          @_output_serializer = serializer
        end
      end
    end
  end
end
