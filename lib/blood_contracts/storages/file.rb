require_relative "file/sampling"

module BloodContracts
  module Storages
    class File < Base
      include Sampling

      def init
        FileUtils.mkdir_p(
          ::File.join(
            BloodContracts.sampling_config.dig(:storage, :root),
            "blood_samples",
            session
          )
        )
      end

      def statistics_per_rule(*rules)
        Hash[
          Array(rules).map do |rule|
            next [rule.to_s, 0] unless File.exists?(stats_path)

            [rule.to_s, samples_count(rule)]
          end
        ]
      end

      # def collect_stats(tag)
      #   stats_file = File.join(stats_path, tag)
      #   File.open("#{stats_path}/input", "a") do |f|
      #     f << "#{name = sample.name(tag)}\r\n"
      #   end
      # end
    end
  end
end
