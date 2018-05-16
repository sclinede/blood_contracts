require "oj"
require_relative "serializer"

module BloodContracts
  class Sampler
    module SerializersWriters
      Serializer = BloodContracts::Samplers::Serializer

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def self.included(klass)
        klass.option :input_serializer,
                     ->(v) { Serializer.call(v) },
                     default: -> { default_serializer }
        klass.option :output_serializer,
                     ->(v) { Serializer.call(v) },
                     default: -> { default_serializer }
        klass.option :meta_serializer,
                     ->(v) { Serializer.call(v) },
                     default: -> { default_serializer }
        klass.option :error_serializer,
                     ->(v) { Serializer.call(v) },
                     default: -> { default_serializer }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def input_serializer=(serializer)
        @input_serializer = Serializer.call(serializer)
      end

      def output_serializer=(serializer)
        @output_serializer = Serializer.call(serializer)
      end

      def meta_serializer=(serializer)
        @meta_serializer = Serializer.call(serializer)
      end

      def error_serializer=(serializer)
        @error_serializer = Serializer.call(serializer)
      end

      def input_writer=(writer)
        @input_writer = self.class.valid_writer(writer)
      end

      def output_writer=(writer)
        @output_writer = self.class.valid_writer(writer)
      end

      def default_serializer
        Serializer.call(nil)
      end
    end
  end
end
