RSpec.describe BloodContracts do
  describe ".session_name" do
    before { BloodContracts.session_name = "External session name" }

    it { expect(BloodContracts.session_name).to eq("External session name") }
  end

  describe ".storage" do
    context "when default configuration" do
      let(:expected_backend) { BloodContracts::Storages::FileBackend }
      it "has assigned storage" do
        expect(BloodContracts.storage.backend).to be_kind_of(expected_backend)
      end
    end

    context "when custom storage configured" do
      before do
        BloodContracts.config { |config| config.storage[:type] = :postgres }
      end
      let(:expected_backend) { BloodContracts::Storages::PostgresBackend }

      it "has assigned custom storage" do
        expect(BloodContracts.storage.backend).to be_kind_of(expected_backend)
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
