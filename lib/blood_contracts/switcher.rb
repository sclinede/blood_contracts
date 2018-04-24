module BloodContracts
  class Switcher
    extend Dry::Initializer
    extend Forwardable

    option :contract_name
    option :storage, default: -> do
      default_storage_klass.new(contract_name, shared_config: self)
    end

    def default_storage_klass
      case BloodContracts.switcher_config[:storage_type].to_s.downcase.to_sym
      # when :redis
      #   BloodContracts::Storages::Redis
      when :postgres
        BloodContracts::Storages::Postgres
      else
        BloodContracts::Storages::Dummy
      end
    end

    def enabled?
      storage.contract_enabled?(contract_name)
    end

    def enable!
      storage.enable_contract!(contract_name)
    end

    def enable_global!
      storage.enable_contracts_global!
    end

    def disable!
      storage.disable_contract!(contract_name)
    end

    def disable_global!
      storage.disable_contracts_global!
    end

    def_delegator :storage, :init
  end
end
