module BloodContracts
  module Storages
    class BaseBackend
      extend Dry::Initializer
      extend Forwardable

      param :storage
      param :example_name
      def_delegators :@storage, :input_writer, :output_writer,
                     :input_serializer, :output_serializer

      def save_sample(_tag, _input, _output, _context)
        raise NotImplementedError
      end

      def serialize_input(_tag, _input, _context)
        raise NotImplementedError
      end

      def serialize_output(_tag, _output, _context)
        raise NotImplementedError
      end

      def suggestion
        raise NotImplementedError
      end
    end
  end
end
