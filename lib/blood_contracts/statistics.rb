module BloodContracts
  class Statistics
    extend Dry::Initializer
    extend Forwardable

    option :contract_name
    option :storage, default: -> do
      default_storage_klass.new(contract_name, statistics: self)
    end

    def default_storage_klass
      case BloodContracts.statistics_config[:storage_type].to_s.downcase.to_sym
      when :memory
        BloodContracts::Storages::Memory
      when :file
        BloodContracts::Storages::File
      when :postgres
        BloodContracts::Storages::Postgres
      # when :redis
      #   BloodContracts::Storages::Redis
      else
        raise "Unknown storage type configured!"
      end
    end

    def_delegators :storage, :init, :total_statistics, :filtered_statistics,
                   :increment_statistics, :period_statistics

    # def period_just_closed?(time = Time.now)
    #   # FIXME: need better way to close periods
    #   period = time.to_i / configured_period
    #   previous_period = period - 1
    #   !storage.statistics_period_closed?(period) &&
    #     !storage.statistics_period_closed?(previous_period)
    # end

    def current_period(time = Time.now)
      time.to_i / configured_period
    end

    def configured_period
      BloodContracts.statistics_config[:period] || 1
    end

    def total
      storage.total_statistics
    end

    def filtered(time: Time.now, period: nil)
      period ||= time.to_i / configured_period
      storage.filtered_statistics(period)
    end

    def guarantees_failed?(period = current_period)
      period_statistics(period).key?(BloodContracts::GUARANTEE_FAILURE)
    end

    def found_unexpected_behavior?(period = current_period)
      period_statistics(period).key?(BloodContracts::UNEXPECTED_BEHAVIOR)
    end

    def found_unexpected_exception?(period = current_period)
      period_statistics(period).key?(BloodContracts::UNEXPECTED_EXCEPTION)
    end

    def store(rule)
      storage.increment_statistics(rule)
    end
  end
end
