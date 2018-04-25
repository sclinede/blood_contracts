RSpec.describe BloodContracts do
  describe ".session_name" do
    before { BloodContracts.session_name = "External session name" }

    it { expect(BloodContracts.session_name).to eq("External session name") }
  end

  describe ".sampler" do
    context "when default configuration" do
      let(:expected_backend) { BloodContracts::Storages::File }
      it "has assigned storage" do
        expect(BloodContracts.sampler.storage).to be_kind_of(expected_backend)
      end
    end

    context "when custom storage configured" do
      before do
        BloodContracts.config do |config|
          config.sampling["storage"] = :postgres
        end
      end
      after do
        BloodContracts.config do |config|
          config.sampling["storage"] = :file
        end
      end
      let(:expected_backend) { BloodContracts::Storages::Postgres }

      it "has assigned storage" do
        expect(BloodContracts.sampler.storage).to be_kind_of(expected_backend)
      end
    end
  end

  describe ".enabled?" do
  end

  describe ".enable!" do
  end

  describe ".disable!" do
  end

  describe ".shared_storage?" do
  end

  describe ".shared_storage?" do
  end
end
