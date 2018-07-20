module BloodContracts
  module Contractable
    def self.extended(klass)
      klass.prepend ContractsAccessor
      klass.class_eval do
        attr_reader :_contracts
        @_contracts = {}
      end
    end

    def method_added(method_name)
      contracts_applied = (Thread.current[:contracts_applied] || [])
      contracts_applied.map do |contract, args, after_call|
        prepend ContractValidator.new(method_name, contract, args, after_call)
      end
      Thread.current[:contracts_applied] = nil
    end

    def contractable(*args, after_call: nil)
      contract = args.shift
      Thread.current[:contracts_applied] ||= []
      Thread.current[:contracts_applied] << [contract, args, after_call]
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

    class ContractValidator < Module
      def initialize(method_name, contract, cargs, after_call)
        super()

        define_contract_initializer(method_name, contract, cargs)

        define_method(method_name) do |*args, **kwargs|
          find_contract(method_name).call(*args, **kwargs) do |meta|
            begin
              result =
                if kwargs.empty?
                  super(*args)
                else
                  super(*args, **kwargs)
                end
            ensure
              Array(after_call).each do |after_call_callback|
                send(after_call_callback, [*args, **kwargs], result, meta)
              end
            end
          end
        end
      end

      def define_contract_initializer(method_name, contract, args)
        key = :"_#{method_name}_contract"
        define_method(key) do
          _contracts.fetch(key) do
            _contracts.store(key, contract.new(*args))
          end
        end
      end
    end
  end
end
