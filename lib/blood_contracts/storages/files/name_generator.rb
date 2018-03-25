module BloodContracts
  module Storages
    module Files
      class NameGenerator
        extend Dry::Initializer
        extend Forwardable

        param :run_name
        param :example_name
        param :default_path
        option :period, optional: true
        option :round, optional: true
        option :root, default: -> { Rails.root.join(path) }
        def_delegator :BloodContracts, :config

        def call(tag)
          File.join(path, current_period.to_s, tag.to_s, current_round.to_s)
        end

        def timestamp
          @timestamp ||= Time.now.to_s(:usec)[8..-3]
        end

        def reset_timestamp!
          @timestamp = nil
        end

        def current_period
          period || Time.now.to_i / (config.sampling["period"] || 1)
        end

        def current_round
          round || timestamp
        end

        def path
          File.join(default_path, run_name, example_name.to_s)
        end

        def find_all(sample_name)
          Dir.glob("#{extract_name_from(sample_name)}*")
        end

        def exists?(sample_name)
          File.exist?("#{extract_name_from(sample_name)}.input")
        end

        def build_with(run_name, period, round)
          self.class.new(
            run_name, example_name, default_path,
            period: period,
            round: round
          )
        end

        def extract_name_from(sample_name)
          run_name, period, found_tag, round = parse(sample_name)
          history_name_generator = build_with(run_name, period, round)
          history_name_generator.call(found_tag)
        end

        def parse(sample_name)
          path_items = sample_name.to_s.split("/")
          period, tag, sample = path_items.pop(3)
          run_n_example_str = path_items.join("/").sub(default_path, "")
          if run_n_example_str.end_with?("*")
            [
              run_n_example_str.chomp("*"),
              period,
              tag,
              sample
            ]
          elsif run_n_example_str.end_with?(example_name)
            [
              run_n_example_str.chomp(example_name),
              period,
              tag,
              sample
            ]
          else
            %w(__no_match__) * 4
          end
        end
      end
    end
  end
end
