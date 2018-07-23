require 'ann'

module BloodContracts
  module Contractable
    def self.extended(klass)
      klass.include Ann
      klass.prepend ContractsAccessor
    end

    module ContractsAccessor
      attr_reader :_contracts
      def initialize(*)
        super
        @_contracts = {}
      end

      def find_contract(method_name)
        send(:"_#{method_name}_contract")
      end
    end

    class ContractDescriptor
      # args - see ContractValidator.new
      def initialize(caller_klass, *args)
        caller_klass.prepend ContractValidator.new(*args)
      end
    end

    def contractable(*args, after_call: nil)
      contract, *contract_args = args
      ann ContractDescriptor, contract, contract_args, after_call
    end

    class ContractValidator < Module
      def initialize(method_name, contract, cargs, after_call)
        super()
        define_contract_initializer(method_name, contract, cargs)
        wrap_method_in_contract(method_name, after_call)
      end

      def define_contract_initializer(method_name, contract, args)
        key = :"_#{method_name}_contract"
        define_method(key) do
          _contracts.fetch(key) { _contracts.store(key, contract.new(*args)) }
        end
      end

      def wrap_method_in_contract(method_name, after_call)
        module_eval <<~RUBY
          def #{method_name}(*args, **kwargs)
            find_contract(:#{method_name}).call(*args, **kwargs) do |meta|
              begin
                result = super(*args, **kwargs)
              ensure
                %i(#{Array(after_call).join(" ")}).each do |after_call_callback|
                  send(after_call_callback, [*args, **kwargs], result, meta)
                end
              end
            end
          end
        RUBY
      end
    end
  end
end
