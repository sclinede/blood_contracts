module BloodContracts::GlobalSwitching
  def enabled?
    switcher.enabled? || config.enabled
  end

  def enable!
    switcher.enable_all!
  end

  def disable!
    switcher.disable_all!
  end
end
