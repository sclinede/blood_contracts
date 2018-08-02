require "oj"

module BloodContracts
  module Samplers
    class Serializer
      extend Dry::Initializer

      param :serializer

      def self.call(*args)
        new(*args).call
      end

      def call
        return default_serializer if serializer.nil?
        return object_serializer_to_hash if object_serializer?
        return serializer.to_hash if hash_serializer?

        raise "Both #dump and #load methods should be defined for serialization"
      end

      private

      def object_serializer?
        serializer.respond_to?(:dump) && serializer.respond_to?(:load)
      end

      def object_serializer_to_hash
        {
          load: serializer.method(:load),
          dump: serializer.method(:dump)
        }
      end

      def default_load(data)
        Oj.load(data, mode: :null, circular: true)
      end

      def default_dump(data)
        Oj.dump(data, mode: :null, circular: true, max_nesting: 10)
      end

      def default_serializer
        { load: method(:default_load), dump: method(:default_dump) }
      end

      def hash_serializer?
        return unless serializer.respond_to?(:to_hash)
        (%i[dump load] - serializer.to_hash.keys).empty?
      end
    end
  end
end
