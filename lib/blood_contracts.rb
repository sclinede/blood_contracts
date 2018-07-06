require "blood_contracts/version"

require "dry-initializer"
require "hashie"

require_relative "blood_contracts/storages/base.rb"
require_relative "blood_contracts/storages/file.rb"
require_relative "blood_contracts/storages/redis.rb"
require_relative "blood_contracts/storages/memory.rb"
require_relative "blood_contracts/storages/postgres.rb"

require_relative "blood_contracts/ext/string_pathize"
require_relative "blood_contracts/ext/string_camelcase"
require_relative "blood_contracts/config"

require_relative "global_switching"
require_relative "global_config"

require_relative "blood_contracts/sampler"
require_relative "blood_contracts/statistics"
require_relative "blood_contracts/switcher"

require_relative "blood_contracts/base_contract"

module BloodContracts
  require_relative "blood_contracts/middleware/chain"

  ALL_CONTRACTS_ACCESS = "*".freeze
  class << self
    attr_reader :sampler
    def reset_sampler!
      @sampler = Sampler.new(contract_name: ALL_CONTRACTS_ACCESS)
    end

    attr_reader :switcher
    def reset_switcher!
      @switcher = Switcher.new(contract_name: ALL_CONTRACTS_ACCESS)
    end
  end

  extend GlobalConfig

  GUARANTEE_FAILURE     = :__guarantee_failure__
  UNEXPECTED_BEHAVIOR   = :__unexpected_behavior__
  UNEXPECTED_EXCEPTION  = :__unexpected_exception__

  class GuaranteesFailure < StandardError; end
  class ExpectationsFailure < StandardError; end
  class UnexpectedException < StandardError; end

  extend GlobalSwitching

  if defined?(RSpec) && RSpec.respond_to?(:configure)
    require_relative "rspec/meet_contract_matcher"
  end

  require_relative "blood_contracts/validator"
  require_relative "default_middleware"
end

require_relative "blood_contracts/runner"
require_relative "blood_contracts/debugger"
