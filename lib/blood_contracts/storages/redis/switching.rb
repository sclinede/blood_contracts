module BloodContracts
  module Storages
    class Redis < Base
      class Switching
        attr_reader :contract_name, :redis
        def initialize(base_storage, redis)
          @contract_name = base_storage.contract_name
          @redis = redis
        end

        def reset!
          redis.del(GLOBAL_CONTRACTS_KEY)
          redis.del(contract_key(contract_name))
        end

        def disable!(a_contract_name = contract_name)
          contract_switcher_set(a_contract_name, false)
        end

        def enable!(a_contract_name = contract_name)
          contract_switcher_set(a_contract_name, true)
        end

        def enable_all!
          global_contracts_switcher_set(true)
        end

        def disable_all!
          global_contracts_switcher_set(false)
        end

        def enabled?(a_contract_name = contract_name)
          contract_state = contract_switcher_state(a_contract_name)
          return contract_state unless contract_state.nil?
          return global_switcher_state if global_state_set?
          BloodContracts.config.enabled
        end

        private

        def global_state_set?
          !global_switcher_state.nil?
        end

        def contract_state_set?(a_contract_name = contract_name)
          !contract_switcher(a_contract_name).nil?
        end

        GLOBAL_CONTRACTS_KEY = "blood_contracts:global-contracts-enabled".freeze

        # rubocop:disable Security/MarshalLoad
        def global_switcher_state
          return unless (value = redis.get(GLOBAL_CONTRACTS_KEY))
          Marshal.load(value)
        end

        def global_contracts_switcher_set(value)
          redis.set(GLOBAL_CONTRACTS_KEY, Marshal.dump(value))
        end

        def contract_switcher_state(a_contract_name)
          return unless (value = redis.get(contract_key(a_contract_name)))
          Marshal.load(value)
        end

        def contract_switcher_set(a_contract_name, value)
          redis.set(contract_key(a_contract_name), Marshal.dump(value))
        end
        # rubocop:enable Security/MarshalLoad

        def contract_key(a_contract_name)
          "blood_contracts:contract-#{a_contract_name}-enabled"
        end
      end
    end
  end
end
