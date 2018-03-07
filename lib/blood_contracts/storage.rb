require_relative "./storages/base_backend.rb"
require_relative "./storages/file_backend.rb"
require_relative "./storages/serializer.rb"

module BloodContracts
  class Storage
    extend Dry::Initializer
    extend Forwardable

    Serializer = BloodContracts::Storages::Serializer
    FileBackend = BloodContracts::Storages::FileBackend

    option :contract_name

    DEFAULT_WRITER = -> (options) do
      "INPUT:\n#{options.input}\n\n#{'=' * 90}\n\nOUTPUT:\n#{options.output}"
    end

    option :input_writer,
           ->(v) { valid_writer(v) }, default: -> { DEFAULT_WRITER }
    option :output_writer,
           ->(v) { valid_writer(v) }, default: -> { DEFAULT_WRITER }

    option :input_serializer,
           ->(v) { Serializer.call(v) }, default: -> { default_serializer }
    option :output_serializer,
           ->(v) { Serializer.call(v) }, default: -> { default_serializer }
    option :meta_serializer,
           ->(v) { Serializer.call(v) }, default: -> { default_serializer }

    option :backend, default: -> { FileBackend.new(self, contract_name) }

    def_delegators :@backend, :sample_exists?,
                   :load_sample, :find_all_samples,
                   :serialize_sample, :describe_sample,
                   :suggestion, :unexpected_suggestion

    def self.valid_writer(writer)
      return writer if writer.respond_to?(:call) || writer.respond_to?(:to_sym)
      raise ArgumentError
    end

    def input_serializer=(serializer)
      @input_serializer = Serializer.call(serializer)
    end

    def output_serializer=(serializer)
      @output_serializer = Serializer.call(serializer)
    end

    def meta_serializer=(serializer)
      @meta_serializer = Serializer.call(serializer)
    end

    def input_writer=(writer)
      @input_writer = self.class.valid_writer(writer)
    end

    def output_writer=(writer)
      @output_writer = self.class.valid_writer(writer)
    end

    UNDEFINED_RULE = :__no_tag_match__
    EXCEPTION_CAUGHT = :__exception_raised__

    def default_serializer
      { load: Oj.method(:load), dump: Oj.method(:dump) }
    end

    def store(options:, rules:, context:)
      options = Hashie::Mash.new(options)

      Array(rules).each do |rule_name|
        describe_sample(rule_name, options, context)
        serialize_sample(rule_name, options, context)
      end
    end
  end
end
