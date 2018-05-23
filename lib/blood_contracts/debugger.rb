module BloodContracts
  class Debugger < Runner
    def runs
      @runs ||= debug_runs # storage.find_all_samples(ENV["debug"]).each
    end

    def iterations
      runs.size
    end

    def call(*)
      return Contracts::Round.new unless debugging_samples_available?

      matcher.call(sampler.load_sample(runs.next)) do |rules|
        # FIXME: replace with Middleware, rememeber to exclude Sampling
        Array(rules).each(&statistics.method(:store))
      end
    end

    # FIXME: move to Decorator
    def description
      return super if debugging_samples_available?
      " skipped in current debugging session"
    end

    private

    def debug_runs
      return sampler.find_all_samples(ENV["debug"]).each if ENV["debug"]
      raise "Nothing to debug!" unless File.exist?(config.debug_file)
      found_samples.each
    end

    def found_samples
      @found_samples ||= File.foreach(config.debug_file)
                             .map { |s| s.delete("\n") }
                             .flat_map do |sample|
        sampler.find_all_samples(sample)
      end.compact
    end

    def config
      BloodContracts.config
    end

    # FIXME: move to Decorator
    def suggestion
      "\n - #{found_samples.join("\n - ")}"
    end

    def debugging_samples_available?
      runs.size.positive?
    end
  end
end
