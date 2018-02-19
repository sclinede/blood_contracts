module BloodContracts
  class Suite
    extend Dry::Initializer

    option :data_generator, optional: true
    option :contract, default: -> { Hashie::Mash.new }
    option :input_writer, optional: true
    option :output_writer, optional: true
    option :storage_backend, optional: true
    option :storage, default: -> { default_storage }

    def data_generator=(generator)
      fail ArgumentError unless generator.respond_to?(:call)
      @data_generator = generator
    end

    def contract=(contract)
      fail ArgumentError unless contract.respond_to?(:to_h)
      @contract = Hashie::Mash.new(contract.to_h)
    end

    def input_writer=(writer)
      storage.input_writer = writer
    end

    def output_writer=(writer)
      storage.output_writer = writer
    end

    def default_storage
      Storage.new(input_writer: input_writer, output_writer: output_writer)
    end
  end
end
