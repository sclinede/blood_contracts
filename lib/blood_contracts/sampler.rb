require_relative "./samplers/utils.rb"
require_relative "./samplers/serializers_writers.rb"
require_relative "./samplers/limiter.rb"

module BloodContracts
  class Sampler
    extend Dry::Initializer
    extend Forwardable

    include SerializersWriters

    option :contract_name
    option :session, optional: true

    DEFAULT_INPUT_WRITER = ->(round) { "INPUT:\n#{round.input}" }
    option :input_writer,
           ->(v) { valid_writer(v) }, default: -> { DEFAULT_INPUT_WRITER }

    DEFAULT_OUTPUT_WRITER = ->(round) { "OUTPUT:\n#{round.output}" }
    option :output_writer,
           ->(v) { valid_writer(v) }, default: -> { DEFAULT_OUTPUT_WRITER }

    def self.valid_writer(writer)
      return writer if writer.respond_to?(:call) || writer.respond_to?(:to_sym)
      raise ArgumentError
    end

    def initialize(*)
      super
      reset_utils!
      reset_storage!
    end

    attr_reader :storage
    def reset_storage!
      @storage =
        default_storage_klass.new(contract_name).tap(&:init).sampling(self)
    end
    def_delegators :storage, :exists?, :load, :find, :find_all,
                   :delete_all, :count

    attr_reader :utils
    def reset_utils!
      @utils = Samplers::Utils.new(current_session, contract_name)
    end

    attr_reader :sample
    def reset_sample!
      @sample = Samplers::Sample.new(utils.path, contract_name)
    end

    def store(round:, rules:, context:)
      return unless BloodContracts.sampling_config[:enabled]
      Array(rules).each do |rule_name|
        reset_sample!
        next if limiter.limit_reached?(rule_name)
        storage.describe(rule_name, round, context)
        storage.serialize(rule_name, round, context)
      end
    end

    private

    def current_session
      session || BloodContracts.session_name || ::Nanoid.generate(size: 10)
    end

    def default_storage_klass
      case storage_type
      when :file
        BloodContracts::Storages::File
      when :postgres
        BloodContracts::Storages::Postgres
      # when :redis
      #   BloodContracts::Storages::Redis
      else
        warn "[#{self.class}] Unsupported storage type"\
             "(#{storage_type}) configured!"
        BloodContracts::Storages::Base
      end
    end

    def storage_type
      BloodContracts.sampling_config[:storage_type].to_s.downcase.to_sym
    end

    def period_size
      BloodContracts.sampling_config[:period] || 1
    end

    def limiter
      Samplers::Limiter.new(contract_name, storage)
    end
  end
end
