require_relative '../blood_contracts/concerns/testable.rb'

module RSpec
  module MeetContractMatcher
    extend RSpec::Matchers::DSL
    # Runner = ::BloodContracts::Runner
    # Debugger = ::BloodContracts::Debugger
    Testable = ::BloodContracts::Concerns::Testable
    Iterator = ::BloodContracts::Contracts::Iterator

    matcher :meet_contract_rules_of do |contract|
      match do |block|
        if contract.debug_enabled?
          @_contract_runner = contract.runner
          block.call
        else
          contract.class.prepend Testable

          @_contract_runner = contract.runner
          iterator = Iterator.new(@_iterations, @_time_to_run)
          @_contract_runner.statistics.iterations_count = iterator.count

          next false if :halt == catch(:unexpected) do
            iterator.next do
              block.call
              next if @_contract_runner.valid?
              throw :unexpected, :halt if @_halt_on_unexpected
            end
          end
        end

        @_contract_runner.valid?
      end

      supports_block_expectations

      failure_message { @_contract_runner.failure_message }

      description { @_contract_runner.description }

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
