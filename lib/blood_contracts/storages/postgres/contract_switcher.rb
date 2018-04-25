module BloodContracts
  module Storages
    class Postgres < Base
      module ContractSwitcher
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
