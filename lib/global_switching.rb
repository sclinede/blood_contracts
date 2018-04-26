module BloodContracts::GlobalSwitching
  def enabled?
    config.enabled || switcher.enabled?
  end

  def enable!
    switcher.enable_all!
  end

  def disable!
    switcher.disable_all!
  end
end
