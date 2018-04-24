require_relative "./samplers/serializer.rb"
require_relative "./samplers/serializers_writers.rb"
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
                   :find_sample, :serialize_sample, :describe_sample,
                   :samples_count

    def load(path = nil, **kwargs)
      kwargs[:session] = kwargs.fetch(:session) { utils.session }
      kwargs[:contract] = kwargs.fetch(:contract) { utils.contract_name }
      storage.load_sample(path, **kwargs)
    end

    def find(path = nil, **kwargs)
      kwargs[:session] = kwargs.fetch(:session) { utils.session }
      kwargs[:contract] = kwargs.fetch(:contract) { utils.contract_name }
      storage.find_sample(path, **kwargs)
    end

    def find_all(path = nil, **kwargs)
      kwargs[:session] = kwargs.fetch(:session) { utils.session }
      kwargs[:contract] = kwargs.fetch(:contract) { utils.contract_name }
      storage.find_all_samples(path, **kwargs)
    end

    def delete_all(path = nil, **kwargs)
      kwargs[:session] = kwargs.fetch(:session) { utils.session }
      kwargs[:contract] = kwargs.fetch(:contract) { utils.contract_name }
      storage.delete_all_samples(path, **kwargs)
    end

    def limiter
      Samplers::Limiter.new(contract_name, storage)
    end

    def self.valid_writer(writer)
      return writer if writer.respond_to?(:call) || writer.respond_to?(:to_sym)
      raise ArgumentError
    end

    include SerializersWriters

    def utils
      @utils ||= Samplers::Utils.new(storage.session, contract_name)
    end

    attr_reader :sample
    def create_sample!
      @sample = Samplers::Sample.new(utils.path, contract_name)
    end

    def current_period(time = Time.now)
      time.to_i / period_size
    end

    def period_size
      BloodContracts.sampling_config[:period] || 1
    end

    def store(round:, rules:, context:)
      return unless BloodContracts.sampling_config[:enabled]
      Array(rules).each do |rule_name|
        next if limiter.limit_reached?(rule_name)
        create_sample!
        storage.describe_sample(rule_name, round, context)
        storage.serialize_sample(rule_name, round, context)
      end
    end
  end
end
