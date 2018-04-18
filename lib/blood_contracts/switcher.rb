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
    def_delegators :storage, :init,
                   :contract_enabled?, :enable_contract!, :disable_contract!,
                   :enable_contracts_global!, :disable_contracts_global!
  end
end
