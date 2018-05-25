require "blood_contracts/version"

require "dry-initializer"
require "hashie"

require_relative "blood_contracts/ext/string_pathize"
require_relative "blood_contracts/config"
require_relative "blood_contracts/storage"
require_relative "blood_contracts/runner"
require_relative "blood_contracts/debugger"
require_relative "blood_contracts/base_contract"

module BloodContracts
  def session_name
    @__contracts_session_name
  end
  module_function :session_name

  def session_name=(run_name)
    @__contracts_session_name = run_name
  end
  module_function :session_name=

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

  ALL_CONTRACTS_ACCESS = ".*".freeze

  def storage
    @storage = Storage.new(contract_name: ALL_CONTRACTS_ACCESS).tap(&:init)
  end
  module_function :storage

  def shared_storage?
    storage_config[:type].to_sym == :postgres
  end
  module_function :shared_storage?

  def storage_config
    @storage_config ||= Hashie.symbolize_keys!(BloodContracts.config.storage)
  end
  module_function :storage_config

  def sampling_config
    @sampling_config ||= Hashie.symbolize_keys!(BloodContracts.config.sampling)
  end
  module_function :sampling_config

  if defined?(RSpec) && RSpec.respond_to?(:configure)
    require_relative "rspec/meet_contract_matcher"
  end
end
