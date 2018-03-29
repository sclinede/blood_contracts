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

  def storage
    @storage ||= Hashie::Hash[BloodContracts.config.storage].symbolize_keys!
  end
  module_function :storage

  def sampling
    @sampling ||= Hashie::Hash[BloodContracts.config.sampling].symbolize_keys!
  end
  module_function :sampling

  if defined?(RSpec) && RSpec.respond_to?(:configure)
    require_relative "rspec/meet_contract_matcher"
  end
end
