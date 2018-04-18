require_relative "./samplers/serializer.rb"
require_relative "./samplers/serializers.rb"
require_relative "./samplers/limiter.rb"

module BloodContracts
  class Sampler
    extend Dry::Initializer
    extend Forwardable

    Serializer = BloodContracts::Samplers::Serializer

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

    option :storage, default: -> do
      default_storage_klass.new(contract_name, sampler: self)
    end

    def default_storage_klass
      case BloodContracts.sampling_config[:storage_type].to_s.downcase.to_sym
      when :file
        BloodContracts::Storages::File
      when :postgres
        BloodContracts::Storages::Postgres
      else
        raise "Unknown storage type configured!"
      end
    end

    def_delegators :storage, :init, :sample_exists?,
                   :load_sample, :find_all_samples, :find_sample,
                   :serialize_sample, :describe_sample, :samples_count,
                   :delete_all_samples
    def limiter
      Samplers::Limiter.new(contract_name, storage)
    end

    def self.valid_writer(writer)
      return writer if writer.respond_to?(:call) || writer.respond_to?(:to_sym)
      raise ArgumentError
    end

    include Serializers

    def utils
      @utils ||= Samplers::Utils.new(storage.session, contract_name)
    end

    attr_reader :sample
    def new_probe!
      @sample = Samplers::Sample.new(utils.path, contract_name)
    end

    def current_period(time = Time.now)
      time.to_i / configured_period
    end

    def configured_period
      BloodContracts.sampling_config[:period] || 1
    end

    def store(round:, rules:, context:)
      return unless BloodContracts.sampling_config[:enabled]
      Array(rules).each do |rule_name|
        next if limiter.limit_reached?(rule_name)
        new_probe!
        storage.describe_sample(rule_name, round, context)
        storage.serialize_sample(rule_name, round, context)
      end
    end
  end
end
