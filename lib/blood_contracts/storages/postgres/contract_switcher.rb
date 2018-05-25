module BloodContracts
  module Storages
    module Postgres
      module ContractSwitcher
        def drop_table!
          query.execute(:drop_tables)
        end

        def create_tables!
          query.execute(:create_tables)
        end
        alias :init :create_tables!

        def disable_contract!(a_contract_name = contract_name)
          query.execute(:disable_contract, contract_name: a_contract_name)
        end

        def enable_contract!(a_contract_name = contract_name)
          query.execute(:enable_contract, contract_name: a_contract_name)
        end

        def enable_contracts_global!
          query.execute(:enable_contracts_global)
        end

        def disable_contracts_global!
          query.execute(:disable_contracts_global)
        end

        def contract_enabled?(a_contract_name = contract_name)
          enabled = query.contract_enabled(a_contract_name)
          return enabled unless enabled.nil?
          BloodContracts.config.enabled
        end
      end
    end
  end
end
