require "spec_helper"

RSpec.describe "Contract Switching" do
  let(:contract) { WeatherUpdateContract.new }

  context "when Memory storage" do
    before do
      BloodContracts.config do |config|
        config.switching["storage"] = :memory
      end
      contract
    end

    context "when contracts disabled in config" do
      before do
        BloodContracts.config do |config|
          config.enabled = false
          config.raise_on_failure = true
          config.switching["storage"] = :memory
        end
        contract
      end
      after { contract.switcher.reset! }

      context "when switcher was not used" do
        it { expect(contract).not_to be_enabled }
      end

      context "when switcher enabled the contract" do
        before { contract.switcher.enable! }

        it { expect(contract).to be_enabled }
      end

      context "when switcher enabled all contracts" do
        before { contract.switcher.enable_all! }

        it { expect(contract).to be_enabled }
      end
    end

    context "when contracts enabled in config" do
      before do
        BloodContracts.config do |config|
          config.enabled = true
          config.raise_on_failure = true
        end
      end

      context "when switcher was not used" do
        it { expect(contract).to be_enabled }
      end

      context "when switcher disabled the contract" do
        before { contract.switcher.disable! }

        it { expect(contract).not_to be_enabled }
      end

      context "when switcher disabled all contracts" do
        before { contract.switcher.disable_all! }

        it { expect(contract).not_to be_enabled }
      end
    end
  end

  context "when Redis storage" do
    before do
      BloodContracts.config do |config|
        config.switching["storage"] = :redis
      end
      contract
    end

    context "when contracts disabled in config" do
      before do
        BloodContracts.config do |config|
          config.enabled = false
          config.raise_on_failure = true
        end
        contract
      end
      after { contract.switcher.reset! }

      context "when switcher was not used" do
        it { expect(contract).not_to be_enabled }
      end

      context "when switcher enabled the contract" do
        before { contract.switcher.enable! }

        it { expect(contract).to be_enabled }
      end

      context "when switcher enabled all contracts" do
        before { contract.switcher.enable_all! }

        it { expect(contract).to be_enabled }
      end
    end

    context "when contracts enabled in config" do
      before do
        BloodContracts.config do |config|
          config.enabled = true
          config.raise_on_failure = true
        end
      end

      context "when switcher was not used" do
        it { expect(contract).to be_enabled }
      end

      context "when switcher disabled the contract" do
        before { contract.switcher.disable! }

        it { expect(contract).not_to be_enabled }
      end

      context "when switcher disabled all contracts" do
        before { contract.switcher.disable_all! }

        it { expect(contract).not_to be_enabled }
      end
    end
  end
end
