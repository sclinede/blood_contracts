module BloodContracts
  class Suite
    extend Dry::Initializer

    option :contract, ->(v) { Hashie::Mash.new(v) }

    option :input_writer,  optional: true
    option :output_writer, optional: true

    option :input_serializer,  optional: true
    option :output_serializer, optional: true
    option :meta_serializer, optional: true

    option :storage_backend, optional: true
    option :storage, default: -> { default_storage }

    def input_writer=(writer)
      storage.input_writer = writer
    end

    def output_writer=(writer)
      storage.output_writer = writer
    end

    def default_storage
      Storage.new(
        input_writer:  input_writer,
        output_writer: output_writer,
        input_serializer:  input_serializer,
        output_serializer: output_serializer,
        meta_serializer:   meta_serializer
      )
    end
  end
end
