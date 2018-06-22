require_relative "serializer"

module BloodContracts
  module Samplers
    module SerializersAccessors
      Serializer = BloodContracts::Samplers::Serializer

      def self.included(klass)
        klass.option :input_serializer,
                     ->(v) { Serializer.call(v) }, default: -> { nil }
        klass.option :output_serializer,
                     ->(v) { Serializer.call(v) }, default: -> { nil }
        klass.option :meta_serializer,
                     ->(v) { Serializer.call(v) }, default: -> { nil }
        klass.option :error_serializer,
                     ->(v) { Serializer.call(v) }, default: -> { nil }
      end

      def self.serializer_accessor(name)
        define_method(name) { instance_variable_get(:"@#{name}") }
        define_method("#{name}=") do |serializer|
          instance_variable_set(:"@#{name}", Serializer.call(serializer))
        end
      end

      serializer_accessor :input_serializer
      serializer_accessor :output_serializer
      serializer_accessor :meta_serializer
      serializer_accessor :error_serializer
    end
  end
end
