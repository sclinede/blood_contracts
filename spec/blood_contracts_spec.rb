RSpec.describe BloodContracts do
  describe ".run_name" do
    before { BloodContracts.run_name = "External run name" }

    it { expect(BloodContracts.run_name).to eq("External run name") }
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

  context "when custom storage configured" do
  end

  context "when custom sampling configured" do
  end

  context "when RSpec is defined" do
  end
end
