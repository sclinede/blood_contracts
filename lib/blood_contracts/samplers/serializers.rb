require "oj"

module BloodContracts
  class Sampler
    module Serializers
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
        { load: Oj.method(:load), dump: Oj.method(:dump) }
      end
    end
  end
end
