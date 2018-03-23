module BloodContracts
  class Debugger < Runner
    def runs
      @runs ||= debug_runs # storage.find_all_samples(ENV["debug"]).each
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

    def debug_runs
      return storage.find_all_samples(ENV["debug"]).each if ENV["debug"]
      raise "Nothing to debug!" unless File.exist?(config.debug_file)
      File.foreach(config.debug_file)
          .map { |s| s.delete("\n") }
          .map do |sample|
            storage.find_sample(sample)
          end.compact.each
    end

    def config
      BloodContracts.config
    end

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
