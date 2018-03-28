require_relative '../blood_contracts/concerns/testable.rb'

module RSpec
  module MeetContractMatcher
    extend RSpec::Matchers::DSL
    # Runner = ::BloodContracts::Runner
    # Debugger = ::BloodContracts::Debugger
    Testable = ::BloodContracts::Concerns::Testable

    matcher :meet_contract_rules_of do |contract|
      match do |block|
        contract.class.prepend Testable unless contract.debug_enabled?
        @_contract_runner = contract.runner

        next false if :halt == catch(:unexpected) do
          @_contract_runner.iterator.next do
            block.call
            next if @_contract_runner.valid?
            throw :unexpected, :halt if @_contract_runner.stop_on_unexpected
          end
        end

        @_contract_runner.valid?
      end

      def _example_name_to_path
        method_missing(:class)
          .name
          .sub("RSpec::ExampleGroups::", "")
          .pathize
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

      chain :during_n_iterations do |iterations|
        @_iterations = Integer(iterations)
      end

      chain :during_n_seconds do |time_to_run|
        @_time_to_run = Float(time_to_run)
      end

      chain :halt_on_unexpected do
        @_halt_on_unexpected = true
      end
    end
  end
end

RSpec.configure do |config|
  config.include ::RSpec::MeetContractMatcher
  config.filter_run_excluding contract: true
  config.before(:suite) do
    BloodContracts.run_name = ::Nanoid.generate(size: 10)
  end
  config.define_derived_metadata(file_path: %r{/spec/contracts/}) do |meta|
    meta[:contract] = true
  end
end
