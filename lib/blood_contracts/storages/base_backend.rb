require 'nanoid'

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


      def sample_exists?(sample_name)
        raise NotImplementedError
      end

      def find_all_samples(run, tag, sample)
        raise NotImplementedError
      end

      def load_sample(_sample_name)
        %i(input output meta).map do |type|
          load_sample_chunk(type, _sample_name)
        end
      end

      def load_sample_chunk(_dump_type, _sample_name)
        raise NotImplementedError
      end

      def describe_sample(_tag, _options, _context)
        raise NotImplementedError
      end

      def serialize_sample(tag, options, context)
        %i(input output meta).each do |type|
          serialize_sample_chunk(type, tag, options, context)
        end
      end

      def serialize_sample_chunk(_type, _tag, _option, _context)
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
