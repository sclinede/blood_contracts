require_relative "statistics/description"

module BloodContracts
  class Statistics
    extend Forwardable

    attr_reader :contract_name
    def initialize(contract_name:)
      @contract_name = contract_name
      reset_storage!
    end

    attr_reader :storage
    def reset_storage!
      @storage =
        default_storage_klass.new(contract_name).tap(&:init).statistics(self)
    end
    def_delegators :storage, :total, :delete_all, :delete, :filter

    def to_s
      Description.new(self).call
    end

    def current(time = Time.now)
      filter(current_period(time)).values.last
    end

    def current_period(time = Time.now)
      time.to_i / period_size
    end

    def period_size
      BloodContracts.statistics_config[:period] || 1
    end

    def guarantees_failed?(period = current_period)
      filter(period).values.last.key?(
        BloodContracts::GUARANTEE_FAILURE
      )
    end

    def found_unexpected_behavior?(period = current_period)
      filter(period).values.last.key?(
        BloodContracts::UNEXPECTED_BEHAVIOR
      )
    end

    def found_unexpected_exception?(period = current_period)
      filter(period).values.last.key?(
        BloodContracts::UNEXPECTED_EXCEPTION
      )
    end

    def store(rule)
      return unless BloodContracts.statistics_config[:enabled]
      storage.increment(rule)
    end
    alias :increment :store

    private

    def current_session
      session || BloodContracts.session_name || ::Nanoid.generate(size: 10)
    end

    def storage_type
      BloodContracts.statistics_config[:storage_type].to_s.downcase.to_sym
    end

    def default_storage_klass
      case storage_type
      when :memory
        BloodContracts::Storages::Memory
      # when :postgres
      #   BloodContracts::Storages::Postgres
      # when :redis
      #   BloodContracts::Storages::Redis
      else
        warn "[#{self.class}] Unsupported storage type"\
             "(#{storage_type}) configured!"
        BloodContracts::Storages::Base
      end
    end
  end
end
