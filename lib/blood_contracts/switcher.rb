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

    def default_storage_klass
      case BloodContracts.switcher_config[:storage_type].to_s.downcase.to_sym
      when :memory
        BloodContracts::Storages::Memory
      when :postgres
        BloodContracts::Storages::Postgres
      else
        BloodContracts::Storages::Base
      end
    end
  end
end
