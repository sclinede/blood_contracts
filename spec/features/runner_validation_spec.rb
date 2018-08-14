require "spec_helper"

RSpec.describe "Contract Runner Validation", type: :feature do
  before do
    BloodContracts.config do |config|
      config.enabled = true
      config.statistics["enabled"] = true
    end
  end
  after do
    contract.statistics.delete_all
    contract.sampler.delete_all
    contract.switcher.reset!
    BloodContracts.reset_config!
  end

  let(:weather_service) { WeatherService.new }
  let(:contract) { WeatherUpdateContract.new }

  context "when guarantee failure" do
    it "raises GuaranteesFailure" do
      expect { contract.call { {} } }
        .to raise_error(BloodContracts::GuaranteesFailure)
      current_stats = contract.statistics.current
      expect(current_stats.key?(BloodContracts::GUARANTEE_FAILURE))
        .to be_truthy
    end
  end

  context "when expected behavior" do
    it "does not raise error" do
      expect { weather_service.update(:london) }.to_not raise_error
      expect(contract.statistics.current.key?("usual")).to be_truthy
    end
  end

  context "when unexpected behavior" do
    it "raises ExpectationsFailure" do
      expect { weather_service.update(:unexpected) }
        .to raise_error(BloodContracts::ExpectationsFailure)
      current_stats = contract.statistics.current
      expect(current_stats.key?(BloodContracts::UNEXPECTED_BEHAVIOR))
        .to be_truthy
    end
  end

  context "when expected exception" do
    it "raises expected error" do
      expect { weather_service.update(:parsing_exception) }
        .to raise_error(JSON::ParserError)
      expect(contract.statistics.current.key?(:parsing_error)).to be_truthy
    end
  end

  context "when unexpected exception" do
    it "raises unexpected error" do
      expect { weather_service.update("Errno::ENOENT, please") }
        .to raise_error(Errno::ENOENT)
      current_stats = contract.statistics.current
      expect(current_stats.key?(BloodContracts::UNEXPECTED_EXCEPTION))
        .to be_truthy
    end
  end
end
