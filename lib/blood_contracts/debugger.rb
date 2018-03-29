module BloodContracts
  class Debugger < Runner
    option :statistics, default: -> { Contracts::Statistics.new(iterations) }

    def runs
      @runs ||= debug_runs # storage.find_all_samples(ENV["debug"]).each
    end

    def iterations
      runs.size
    end

    def call(args: nil, kwargs: nil, output: "", meta: {}, error: nil)
      return [] unless debugging_samples?

      data = storage.load_sample(runs.next)
      matcher.call(*data, statistics: statistics)
      data
    end

    def description
      return super if debugging_samples?
      "be skipped in current debugging session"
    end

    private

    def debug_runs
      return storage.find_all_samples(ENV["debug"]).each if ENV["debug"]
      raise "Nothing to debug!" unless File.exist?(config.debug_file)
      found_samples.each
    end

    def found_samples
      @found_samples ||= File.foreach(config.debug_file)
                             .map { |s| s.delete("\n") }
                             .flat_map do |sample|
                               storage.find_all_samples(sample)
                              end.compact
    end

    def config
      BloodContracts.config
    end

    def unexpected_suggestion
      ENV["debug"] || "\n - #{found_samples.join("\n - ")}"
    end

    def suggestion
      ENV["debug"] || "\n - #{found_samples.join("\n - ")}"
    end

    def debugging_samples?
      runs.size.positive?
    end
  end
end
