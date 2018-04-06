require "oj"
require_relative "./storages/base_backend.rb"
require_relative "./storages/file_backend.rb"
require_relative "./storages/postgres_backend.rb"
require_relative "./storages/serializer.rb"
require_relative "./storages/sampler.rb"

module BloodContracts
  class Storage
    extend Dry::Initializer
    extend Forwardable

    Serializer = BloodContracts::Storages::Serializer

    option :contract_name

    DEFAULT_WRITER = ->(round) do
      "INPUT:\n#{round.input}\n\n#{'=' * 90}\n\nOUTPUT:\n#{round.output}"
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
    option :error_serializer,
           ->(v) { Serializer.call(v) }, default: -> { default_serializer }

    option :backend, default: -> do
      default_storage_klass.new(self, contract_name)
    end

    def_delegators :@backend, :sample_exists?,
                   :load_sample, :find_all_samples, :find_sample,
                   :serialize_sample, :describe_sample,
                   :suggestion, :unexpected_suggestion, :init,
                   :contract_enabled?, :enable_contract!, :disable_contract!,
                   :enable_contracts_global!, :disable_contracts_global!

    def default_storage_klass
      case BloodContracts.storage_config[:type].downcase.to_sym
      when :file
        BloodContracts::Storages::FileBackend
      when :postgres
        BloodContracts::Storages::PostgresBackend
      else
        raise "Unknown storage type configured!"
      end
    end

    def sampler
      @sampler ||= Storages::Sampler.new(contract_name, backend)
    end

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

    def error_serializer=(serializer)
      @error_serializer = Serializer.call(serializer)
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

    def store(round:, rules:, context:)
      return unless BloodContracts.config.store
      Array(rules).each do |rule_name|
        next if sampler.limit_reached?(rule_name)
        describe_sample(rule_name, round, context)
        serialize_sample(rule_name, round, context)
      end
    end
  end
end
