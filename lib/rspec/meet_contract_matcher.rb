module RSpec
  module MeetContractMatcher
    extend RSpec::Matchers::DSL
    Runner = ::BloodContracts::Runner
    Debugger = ::BloodContracts::Debugger

    matcher :meet_contract_rules do |args|
      match do |subject|
        runner = ENV["debug"] ? Debugger : Runner

        @_contract_runner = runner.new(
          subject,
          context: self,
          suite: build_suite(args || subject),
          iterations: @_iterations,
          time_to_run: @_time_to_run,
          stop_on_unexpected: @_halt_on_unexpected,
        )
        @_contract_runner.call
      end

      def build_suite(args)
        suite = nil
        if args.respond_to?(:to_contract_suite)
          suite = args.to_contract_suite(name: _example_name_to_path)
        elsif args.respond_to?(:to_h) && args.to_h.fetch(:contract) { false }
          ::BloodContracts::Suite.new(
            storage: new_storage,
            contract: args[:contract]
          )
        else
          raise "Matcher arguments is not a Blood Contract"
        end
        suite.data_generator = @_generator if @_generator
        suite
      end

      def new_storage
        storage = Storage.new(contract_name: _example_name_to_path)
        storage.input_writer  = _input_writer  if _input_writer
        storage.output_writer = _output_writer if _output_writer
        if @_input_serializer
          storage.input_serializer  = @_input_serializer
        end
        if @_output_serializer
          storage.output_serializer = @_output_serializer
        end
        storage
      end

      def _example_name_to_path
        method_missing(:class)
          .name
          .sub("RSpec::ExampleGroups::", "")
          .pathize
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
