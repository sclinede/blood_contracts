require "blood_contracts/version"

require_relative "extensions/string.rb"
require "dry-initializer"
require "hashie/mash"

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

  if defined?(RSpec) && RSpec.respond_to?(:configure)
    require_relative "rspec/meet_contract_matcher"

    RSpec.configure do |config|
      config.include ::RSpec::MeetContractMatcher
      config.filter_run_excluding contract: true
      config.before(:suite) do
        BloodContracts.run_name = ::Nanoid.generate(size: 10)
      end
      config.define_derived_metadata(file_path: %r{/spec/contracts/}) do |meta|
        meta[:contract] = true
      end
    end
  end
end
