module BloodContracts::GlobalSwitching
  def enabled?
    config.enabled || switcher.contract_enabled?
  end

  def enable!
    switcher.enable_contracts_global!
  end

  def disable!
    switcher.disable_contracts_global!
  end
end
