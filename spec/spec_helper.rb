require "bundler/setup"

require "dotenv"
Dotenv.load(".env.test")
require "blood_contracts"

require_relative "support/weather_service"
require_relative "support/weather_update_contract"

apply_contract

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) { BloodContracts.reset_config! }
  config.after(:each) do
    BloodContracts.reset_config!
    BloodContracts.session_name = ::Nanoid.generate(size: 12)
  end
end
