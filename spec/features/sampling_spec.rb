require "spec_helper"

RSpec.describe "Contract Sampling" do
  apply_contract

  before do
    BloodContracts.config do |config|
      config.enabled = true
      config.sampling["enabled"] = true
      config.sampling["period"] = 3600
      config.sampling["limit_per_tag"] = {
        default: 3,
        critical_data: 5
      }
    end
  end
  after { contract.sampler.delete_all }
  after { contract.statistics.delete_all }

  let(:default_tag_limit) { 3 }
  let(:weather_service) { WeatherService.new }
  let(:contract) { WeatherUpdateContract.new }

  describe "Sample contents" do
    before do
      weather_service.update(:london)
      weather_service.update(:saint_p)
      weather_service.update(:code_404)
      weather_service.update(:parsing_exception) rescue nil
      weather_service.update(:unexpected) rescue nil
      weather_service.update("Errno::ENOENT, please") rescue nil
      contract.call { {} } rescue nil
    end

    let(:response) { kind_of(::WeatherService::Response) }
    let(:meta) { hash_including("checked_rules" => kind_of(Array)) }

    def load_sample(rule)
      contract.sampler.load(rule: rule)
    end

    context "when sample is :usual" do
      let(:input) do
        hash_including(
          "args" => [:saint_p],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: :usual)
        expect(round.input).to match(input)
        expect(round.response).to match(response)
        expect(round.response.temperature).to eq(8.5)
        expect(round.response.city).to eq("Saint-Petersburg")
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
    end

    context "when sample is :client_error" do
      let(:input) do
        hash_including(
          "args" => [:code_404],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: :client_error)
        expect(round.input).to match(input)
        expect(round.response).to match(response)
        expect(round.response.code).to eq("404")
        expect(round.response.error).to eq("Internal error")
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
    end

    context "when sample is :parsing_error" do
      let(:input) do
        hash_including(
          "args" => [:parsing_exception],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: :parsing_error)
        expect(round.input).to match(input)
        expect(round.response).to be_nil
        expect(round.input_preview).to match(/args.*parsing_exception/)
        expect(round.response_preview).to match(/xml/)
        expect(round.error.keys).to include(JSON::ParserError.to_s)
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
        expect { JSON.parse(round.meta["raw_response"]) }
          .to raise_error(JSON::ParserError)
      end
    end

    context "when sample is :__guarantee_failure__" do
      let(:input) do
        hash_including(
          "args" => [],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: BloodContracts::GUARANTEE_FAILURE)
        expect(round.input).to match(input)
        expect(round.response).to be_nil
        expect(round.input_preview).to match(/args.*\[\]/)
        expect(round.response_preview).to match(//)
        expect(round.error).to be_empty
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(1)
      end
    end

    context "when sample is :__unexpected_behavior__" do
      let(:input) do
        hash_including(
          "args" => [:unexpected],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: BloodContracts::UNEXPECTED_BEHAVIOR)
        expect(round.input).to match(input)
        expect(round.response).to match(response)
        expect(round.input_preview).to match(/args.*unexpected/)
        expect(round.response_preview).to match(//)
        expect(round.error).to be_empty
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
    end

    context "when sample is :__unexpected_exception__" do
      let(:input) do
        hash_including(
          "args" => ["Errno::ENOENT, please"],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(
          rule: BloodContracts::UNEXPECTED_EXCEPTION
        )
        expect(round.input).to match(input)
        expect(round.response).to be_nil
        expect(round.input_preview).to match(/args.*Errno::ENOENT, please/)
        expect(round.response_preview).to match(//)
        expect(round.error.keys).to include(Errno::ENOENT.to_s)
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
    end

    context "when sample is :saint_p_weather" do
      let(:input) do
        hash_including(
          "args" => [:saint_p],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: :saint_p_weather)
        expect(round.input).to match(input)
        expect(round.response).to match(response)
        expect(round.response.temperature).to eq(8.5)
        expect(round.response.city).to eq("Saint-Petersburg")
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
    end

    context "when sample is :london_weather" do
      let(:input) do
        hash_including(
          "args" => [:london],
          "kwargs" => {}
        )
      end

      it "loads sample correctly" do
        round = contract.sampler.load(rule: :london_weather)
        expect(round.input).to match(input)
        expect(round.response).to match(response)
        expect(round.response.temperature).to eq(8.5)
        expect(round.response.city).to eq("London")
        expect(round.meta).to match(meta)
        expect(round.meta["checked_rules"].size).to eq(8)
      end
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
      contract.call { {} } rescue nil
    end

    it "creates one sample per rule" do
      expect(contract.sampler.count(:client_error)).to eq(2)
      expect(contract.sampler.count(:server_error)).to eq(0)
      expect(contract.sampler.count(:parsing_error)).to eq(1)
      expect(contract.sampler.count(:timeout_error)).to eq(1)
      expect(contract.sampler.count(:saint_p_weather)).to eq(1)
      expect(contract.sampler.count(:london_weather)).to eq(1)
      expect(contract.sampler.count(:usual)).to eq(2)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(1)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(1)
      expect(
        contract.sampler.count(BloodContracts::GUARANTEE_FAILURE)
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
        contract.call { {} } rescue nil
      end
    end

    it "creates number of samples eq to limit" do
      expect(contract.sampler.count(:client_error)).to eq(10)
      expect(contract.sampler.count(:server_error)).to eq(0)
      expect(contract.sampler.count(:parsing_error)).to eq(5)
      expect(contract.sampler.count(:saint_p_weather)).to eq(5)
      expect(contract.sampler.count(:london_weather)).to eq(5)
      expect(contract.sampler.count(:usual)).to eq(3)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(5)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(5)
      expect(
        contract.sampler.count(BloodContracts::GUARANTEE_FAILURE)
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
        contract.call { {} } rescue nil
      end
    end

    it "creates number of samples eq to limit" do
      expect(contract.sampler.count(:client_error)).to eq(30)
      expect(contract.sampler.count(:server_error)).to eq(0)
      expect(contract.sampler.count(:parsing_error)).to eq(15)
      expect(contract.sampler.count(:saint_p_weather)).to eq(5)
      expect(contract.sampler.count(:london_weather)).to eq(5)
      expect(contract.sampler.count(:usual)).to eq(3)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_BEHAVIOR)
      ).to eq(15)
      expect(
        contract.sampler.count(BloodContracts::UNEXPECTED_EXCEPTION)
      ).to eq(15)
      expect(
        contract.sampler.count(BloodContracts::GUARANTEE_FAILURE)
      ).to eq(15)
    end
  end
end
