module BloodContracts
  module Storages
    class Postgres < Base
      class Switching
        attr_reader :query, :contract_name
        def initialize(query, contract_name)
          @query = query
          @contract_name = contract_name
        end

        def disable!
          query.execute(:disable_contract, contract_name: contract_name)
        end

        def enable!
          query.execute(:enable_contract, contract_name: contract_name)
        end

        def enable_all!
          query.execute(:enable_contracts_global)
        end

        def disable_all!
          query.execute(:disable_contracts_global)
        end

        def enabled?
          enabled = query.contract_enabled(a_contract_name)
          return BloodContracts.config.enabled if enabled.nil?
          enabled
        end
      end
    end
  end
end
