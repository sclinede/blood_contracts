require "spec_helper"

RSpec.describe "Contract Rules Matching" do
  apply_contract

  before do
    BloodContracts.config do |config|
      config.enabled = true
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

  describe "Usual behavior" do
    it "do not fail the behavior" do
      expect { weather_service.update(:london) }.not_to raise_error
    end
  end

  describe "Exception in behavior" do
    context "when exception was predicted" do
      it "do not prevent flow to continue" do
        expect { weather_service.update(:timeout) }
          .to raise_error(Timeout::Error)
      end
    end

    context "when exception was not predicted" do
      it "do not prevent flow to continue" do
        expect { weather_service.update(ArgumentError) }
          .to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "Custom behavior" do
    it "do not prevent flow to continue" do
      expect { weather_service.update(:saint_p) }.not_to raise_error
    end
  end

  describe "Guarantee failure" do
    it "prevents flow from continue" do
      expect { contract.call { {} } }
        .to raise_error(BloodContracts::GuaranteesFailure)
    end
  end

  describe "Unexpected behavior" do
    it "prevents flow from continue" do
      expect { weather_service.update(:unexpected) }
        .to raise_error(BloodContracts::ExpectationsFailure)
    end
  end
end
