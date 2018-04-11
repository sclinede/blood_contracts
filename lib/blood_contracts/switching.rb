module BloodContracts
  module Switching
    using StringPathize

    def enable!
      Thread.current[name] = true
    end

    def disable!
      Thread.current[name] = false
    end

    def reset!
      Thread.current[name] = nil
    end

    def enabled?
      if Thread.current[name].nil?
        Thread.current[name] = storage.contract_enabled?
      end
      !!Thread.current[name]
    end

    private

    def name
      to_s.pathize
    end
  end
end
