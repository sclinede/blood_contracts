module BloodContracts
  class BaseContract
    extend Dry::Initializer
    param :checking_proc

    def call(data = data_generator.call)
      checking_proc.call(data)
    end

    def contract
      fail NotImplementedError
    end

    def build_storage(name)
      storage = Storage.new(example_name: name)
      storage.input_writer  = method(:input_writer)  if defined? input_writer
      storage.output_writer = method(:output_writer) if defined? output_writer
      if defined? input_serializer
        storage.input_serializer = input_serializer
      end
      if defined? output_serializer
        storage.output_serializer = output_serializer
      end
      storage
    end

    def to_contract_suite(name: self.class.to_s)
      Suite.new(storage: build_storage(name), contract: contract)
    end
  end
end
