module BloodContracts
  module Storages
    class BaseBackend
      extend Dry::Initializer
      extend Forwardable

      param :storage
      param :example_name
      option :name, default: -> do
        BloodContracts.run_name || ::Nanoid.generate(size: 10)
      end
      def_delegators :@storage, :input_writer, :output_writer,
                     :input_serializer, :output_serializer, :meta_serializer

      def find_all_samples(run, tag, sample)
        raise NotImplementedError
      end

      def save_sample(_tag, _options, _context)
        raise NotImplementedError
      end

      def serialize_input(_tag, _options, _context)
        raise NotImplementedError
      end

      def serialize_output(_tag, _options, _context)
        raise NotImplementedError
      end

      def serialize_meta(_tag, _options, _context)
        raise NotImplementedError
      end

      def suggestion
        raise NotImplementedError
      end

      def unexpected_suggestion
        raise NotImplementedError
      end
    end
  end
end
