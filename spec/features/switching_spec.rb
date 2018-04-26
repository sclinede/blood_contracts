require "spec_helper"

RSpec.describe "Contract Switching" do
  apply_contract

  before do
    BloodContracts.config do |config|
      config.enabled = true
      config.raise_on_failure = true
      config.switching["enabled"] = true
      config.sampling["enabled"] = false
      config.statistics["enabled"] = false
    end
  end
end
