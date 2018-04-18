require "bundler/setup"
require "blood_contracts"
require "dotenv"
Dotenv.load(".env.test")

require_relative "support/weather_contract"
require_relative "support/weather_service"

WeatherContract.apply_to(klass: WeatherService, methods: :update)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
