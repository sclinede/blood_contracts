module BloodContracts
  class BaseContract
    extend Dry::Initializer
    option :action

    def call(data)
      action.call(data)
    end

    def contract
      fail NotImplementedError
    end

    def input_serializer
      nil
    end

    def output_serializer
      nil
    end

    def build_storage(name)
      storage = Storage.new(example_name: name)
      storage.input_writer  = method(:input_writer)  if defined? input_writer
      storage.output_writer = method(:output_writer) if defined? output_writer
      storage.input_serializer = input_serializer
      storage.output_serializer = output_serializer
      storage
    end

    def to_contract_suite(name: self.class.to_s)
      Suite.new(storage: build_storage(name), contract: contract)
    end
  end
end
