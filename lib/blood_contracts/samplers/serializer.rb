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

      def default_serializer
        { load: Oj.method(:load), dump: Oj.method(:dump) }
      end

      def hash_serializer?
        return unless serializer.respond_to?(:to_hash)
        (%i[dump load] - serializer.to_hash.keys).empty?
      end
    end
  end
end
