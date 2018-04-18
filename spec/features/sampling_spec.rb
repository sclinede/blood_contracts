require "spec_helper"

RSpec.describe "Contract Sampling" do
  before do
    BloodContracts.config do |config|
      config.enabled = true
      config.raise_on_failure = true
      config.sampling["enabled"] = true
      config.sampling["period"] = 3600
      config.sampling["limit_per_tag"] = {
        default: 3,
        critical_data: 5,
      }
    end
  end
  after do
    contract.sampler.delete_all_samples(
      session: contract.sampler.utils.session,
      contract: contract.sampler.utils.contract_name
    )
  end

  let(:default_tag_limit) { 3 }

  let(:weather_service) { WeatherService.new }
  let(:contract) { WeatherContract.new }

  describe "Sample contents" do
    before do
      weather_service.update(:london)
      weather_service.update(:code_404)
      weather_service.update(:parsing_exception) rescue nil
      weather_service.update(:unexpected) rescue nil
    end

    def load_sample(rule)
      contract.sampler.load_sample(
        rule: rule,
        session: contract.sampler.utils.session,
        contract: contract.name
      )
    end

    it "loads :usual sample correctly" do


    end

    it "loads :client_error sample correctly" do

    end

    it "loads :parsing_exception sample correctly" do

    end

    it "loads :__unexpected_behavior__ sample correctly" do

    end
  end

  describe "Samples count below limit" do
    before do
      weather_service.update(:london)
      weather_service.update(:saint_p)
      weather_service.update(:code_401)
      weather_service.update(:code_404)
      weather_service.update("Errno::ENOENT, please") rescue nil
      weather_service.update(:parsing_exception) rescue nil
      weather_service.update(:unexpected) rescue nil
      weather_service.update(:timeout) rescue nil
      contract.call { Hash.new } rescue nil
    end

    it "creates one sample per rule" do
      expect(contract.sampler.samples_count(:client_error)).to eq(2)
      expect(contract.sampler.samples_count(:server_error)).to eq(0)
      expect(contract.sampler.samples_count(:parsing_error)).to eq(1)
      expect(contract.sampler.samples_count(:timeout_error)).to eq(1)
      expect(contract.sampler.samples_count(:saint_p_weather)).to eq(1)
      expect(contract.sampler.samples_count(:london_weather)).to eq(1)
      expect(contract.sampler.samples_count(:usual)).to eq(2)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(1)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(1)
      expect(
        contract.sampler.samples_count(BloodContracts::GUARANTEE_FAILURE)
      ).to eq(1)
    end
  end

  describe "Samples count equal to limit" do
    before do
      5.times do
        weather_service.update(:london)
        weather_service.update(:saint_p)
        weather_service.update(:code_401)
        weather_service.update(:code_404)
        weather_service.update("Errno::ENOENT, please") rescue nil
        weather_service.update(:parsing_exception) rescue nil
        weather_service.update(:unexpected) rescue nil
        contract.call { Hash.new } rescue nil
      end
    end

    it "creates number of samples eq to limit" do
      expect(contract.sampler.samples_count(:client_error)).to eq(10)
      expect(contract.sampler.samples_count(:server_error)).to eq(0)
      expect(contract.sampler.samples_count(:parsing_error)).to eq(5)
      expect(contract.sampler.samples_count(:saint_p_weather)).to eq(5)
      expect(contract.sampler.samples_count(:london_weather)).to eq(5)
      expect(contract.sampler.samples_count(:usual)).to eq(3)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(5)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(5)
      expect(
        contract.sampler.samples_count(BloodContracts::GUARANTEE_FAILURE)
      ).to eq(5)
    end
  end

  describe "Samples count over the limit" do
    before do
      15.times do
        weather_service.update(:london)
        weather_service.update(:saint_p)
        weather_service.update(:code_401)
        weather_service.update(:code_404)
        weather_service.update("Errno::ENOENT, please") rescue nil
        weather_service.update(:parsing_exception) rescue nil
        weather_service.update(:unexpected) rescue nil
        contract.call { Hash.new } rescue nil
      end
    end

    it "creates number of samples eq to limit" do
      expect(contract.sampler.samples_count(:client_error)).to eq(30)
      expect(contract.sampler.samples_count(:server_error)).to eq(0)
      expect(contract.sampler.samples_count(:parsing_error)).to eq(15)
      expect(contract.sampler.samples_count(:saint_p_weather)).to eq(5)
      expect(contract.sampler.samples_count(:london_weather)).to eq(5)
      expect(contract.sampler.samples_count(:usual)).to eq(3)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(15)
      expect(
        contract.sampler.samples_count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(15)
      expect(
        contract.sampler.samples_count(BloodContracts::GUARANTEE_FAILURE)
      ).to eq(15)
    end
  end
end
