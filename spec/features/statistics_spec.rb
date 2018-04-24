require "spec_helper"
require "timecop"

RSpec.describe "Contract Statistics", type: :feature do
  apply_contract

  before do
    BloodContracts.config do |config|
      config.enabled = true
      config.raise_on_failure = true
      config.statistics["enabled"] = true
    end
  end
  after { contract.statistics.clear_all! }

  let(:weather_service) { WeatherService.new }
  let(:contract) { WeatherUpdateContract.new }

  context "when all matches are in current period" do
    before do
      5.times do
        weather_service.update(:london)
        weather_service.update(:saint_p)
        weather_service.update(:code_401)
        weather_service.update(:code_404)
      end
      9.times do
        weather_service.update(:parsing_exception) rescue nil
        weather_service.update(:unexpected) rescue nil
      end
      weather_service.update("Errno::ENOENT, please") rescue nil
      contract.call { {} } rescue nil
    end

    it "returns valid statistics" do
      expect(contract.statistics.current).to match(hash_including({
          usual: 10,
          london_weather: 5,
          saint_p_weather: 5,
          client_error: 10,
          parsing_error: 9,
          __unexpected_behavior__: 9,
          __unexpected_exception__: 1,
          __guarantee_failure__: 1
        }))
    end
  end

  context "when matches split between periods" do
    before do
      Timecop.freeze(Time.new(2018, 01, 01, 13, 00))
      5.times do
        weather_service.update(:london)
        weather_service.update(:saint_p)
        weather_service.update(:code_401)
        weather_service.update(:code_404)
      end

      Timecop.freeze(Time.new(2018, 01, 01, 14, 00))
      9.times do
        weather_service.update(:parsing_exception) rescue nil
        weather_service.update(:unexpected) rescue nil
      end
      weather_service.update("Errno::ENOENT, please") rescue nil
      contract.call { {} } rescue nil
    end
    after { Timecop.return }

    let(:previous_period_statistics) do
      contract.statistics.filtered(time: Time.new(2018, 01, 01, 13, 24))
        .values.first
    end

    it "returns valid statistics" do
      expect(contract.statistics.current).to match(hash_including({
        parsing_error: 9,
        __unexpected_behavior__: 9,
        __unexpected_exception__: 1,
        __guarantee_failure__: 1
      }))
      expect(previous_period_statistics).to match(hash_including({
        usual: 10,
        london_weather: 5,
        saint_p_weather: 5,
        client_error: 10
      }))
      expect(contract.statistics.total.values).to match_array([
        {
          parsing_error: 9,
          __unexpected_behavior__: 9,
          __unexpected_exception__: 1,
          __guarantee_failure__: 1
        },
        {
          usual: 10,
          london_weather: 5,
          saint_p_weather: 5,
          client_error: 10
        }
      ])
    end
  end
end
