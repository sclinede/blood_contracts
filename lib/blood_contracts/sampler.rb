require_relative "./samplers/utils.rb"
require_relative "./samplers/serializers_accessors.rb"
require_relative "./samplers/preview_accessors.rb"
require_relative "./samplers/limiter.rb"

module BloodContracts
  class Sampler
    extend Dry::Initializer
    extend Forwardable

    option :contract_name
    option :session, optional: true

    include Samplers::SerializersAccessors
    include Samplers::PreviewersAccessors

    def initialize(*)
      super
      reset_utils!
      reset_storage!
      reset_sample!
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
      Array(rules).each do |rule_name|
        reset_sample!
        next if limiter.limit_reached?(rule_name)
        storage.preview(rule_name, round, context)
        storage.serialize(rule_name, round, context)
      end
    end

    def current_session
      session || BloodContracts.session_name || ::Nanoid.generate(size: 10)
    end

    def storage_type
      BloodContracts.sampling_config[:storage_type].to_s.downcase.to_sym
    end

    private

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

    def period_size
      BloodContracts.sampling_config[:period] || 1
    end

    def limiter
      Samplers::Limiter.new(contract_name, storage)
    end

    class Middleware
      def call(contract, round, rules, context)
        contract.sampler.store(round: round, rules: rules, context: context)
        yield
      end
    end
  end
end
