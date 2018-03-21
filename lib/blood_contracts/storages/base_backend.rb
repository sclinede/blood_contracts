require "nanoid"

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
                     :input_serializer, :output_serializer, :meta_serializer,
                     :error_serializer

      def sample_exists?(_sample_name)
        raise NotImplementedError
      end

      def find_all_samples(_run, _tag, _sample)
        raise NotImplementedError
      end

      def load_sample(_sample_name)
        %i(input output meta error).map do |type|
          load_sample_chunk(type, _sample_name)
        end
      end

      def load_sample_chunk(_dump_type, _sample_name)
        raise NotImplementedError
      end

      def describe_sample(_tag, _round, _context)
        raise NotImplementedError
      end

      def serialize_sample(tag, round, context)
        %i(input output meta error).each do |type|
          serialize_sample_chunk(type, tag, round, context)
        end
      end

      def serialize_sample_chunk(_type, _tag, _round, _context)
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
