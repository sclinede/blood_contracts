module BloodContracts
  class Debugger < Runner
    def runs
      @runs ||= suite.storage.find_all(ENV["debug"]).each
    end

    def iterations
      runs.size
    end

    def call
      return super if debugging_samples?
      true
    end

    def description
      return super if debugging_samples?
      "be skipped in current debugging session"
    end

    private

    def match_rules
      rules, _ = contract.match { suite.storage.load_run(runs.next) }
      rules
    end

    def unexpected_further_investigation
      ENV["debug"]
    end

    def further_investigation
      ENV["debug"]
    end

    def debugging_samples?
      runs.size.positive?
    end
  end
end
