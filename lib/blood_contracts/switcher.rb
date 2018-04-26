module BloodContracts
  class Switcher
    extend Forwardable

    attr_reader :contract_name
    def initialize(contract_name:)
      @contract_name = contract_name
      reset_storage!
    end

    attr_reader :storage
    def reset_storage!
      @storage =
        default_storage_klass.new(contract_name).tap(&:init).switching(self)
    end

    def default_storage_klass
      case BloodContracts.switcher_config[:storage_type].to_s.downcase.to_sym
      # when :redis
      #   BloodContracts::Storages::Redis
      when :postgres
        BloodContracts::Storages::Postgres
      else
        BloodContracts::Storages::Base
      end
    end

    def enabled?
      storage.enabled?
    end

    def enable!
      storage.enable!
    end

    def disable!
      storage.disable!
    end

    def enable_all!
      storage.enable_all!
    end

    def disable_all!
      storage.disable_all!
    end
  end
end
