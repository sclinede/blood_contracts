require "blood_contracts/version"

require "dry-initializer"
require "hashie/mash"

require_relative "blood_contracts/ext/string_pathize"
require_relative "blood_contracts/config"
require_relative "blood_contracts/suite"
require_relative "blood_contracts/storage"
require_relative "blood_contracts/runner"
require_relative "blood_contracts/debugger"
require_relative "blood_contracts/base_contract"

module BloodContracts
  def run_name
    @__contracts_run_name
  end
  module_function :run_name

  def run_name=(run_name)
    @__contracts_run_name = run_name
  end
  module_function :run_name=

  def config
    @config ||= Config.new
    yield @config if block_given?
    @config
  end
  module_function :config

  def enabled?
    config.enabled || storage.backend.contract_enabled?
  end
  module_function :enabled?

  def enable!
    storage.enable_contracts_global!
  end
  module_function :enable!

  def disable!
    storage.disable_contracts_global!
  end
  module_function :disable!

  def storage
    @storage = Storage.new(contract_name: '.*').tap(&:init)
  end
  module_function :storage

  def shared_storage?
    storage_config[:type].to_sym == :postgres
  end
  module_function :shared_storage?

  def storage_config
    @storage_config ||=
      Hashie::Hash[BloodContracts.config.storage].symbolize_keys!
  end
  module_function :storage_config

  def sampling_config
    @sampling ||= Hashie::Hash[BloodContracts.config.sampling].symbolize_keys!
  end
  module_function :sampling_config

  if defined?(RSpec) && RSpec.respond_to?(:configure)
    require_relative "rspec/meet_contract_matcher"
  end
end
