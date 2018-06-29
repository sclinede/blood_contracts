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

    def_delegators :storage, :enable!, :disable!, :enable_all!, :disable_all!,
                   :enabled?, :reset!

    private

    STORAGES_MAP = {
      redis: BloodContracts::Storages::Redis,
      memory: BloodContracts::Storages::Memory,
      postgres: BloodContracts::Storages::Postgres
    }.freeze

    def configured_storage_type
      BloodContracts.switcher_config[:storage_type].to_s.downcase.to_sym
    end

    def default_storage_klass
      STORAGES_MAP.fetch(configured_storage_type) do
        warn "[#{self.class}] Unsupported storage type"\
             "(#{storage_type}) configured!"
        BloodContracts::Storages::Base
      end
    end

    class Middleware
      def call(contract, _round, _rules, _context)
        # TODO: do not propogate if switcher disabled!
        yield if contract.switcher.enabled?
      end
    end
  end
end
