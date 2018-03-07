module BloodContracts
  class Debugger < Runner
    def runs
      @runs ||= storage.find_all_samples(ENV["debug"]).each
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

    def match_rules?(matches_storage:)
      matcher.call(*storage.load_sample(runs.next), storage: matches_storage)
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
