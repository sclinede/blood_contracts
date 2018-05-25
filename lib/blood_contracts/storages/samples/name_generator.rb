module BloodContracts
  module Storages
    module Samples
      class NameGenerator
        extend Dry::Initializer

        param :session
        param :contract_name
        param :default_path
        option :period, optional: true
        option :round, optional: true
        if defined?(Rails)
          option :root, default: -> { Rails.root.join(path) }
        else
          option :root, default: -> { File.join(Dir.tmpdir, path) }
        end

        def call(tag)
          File.join(path, current_period.to_s, tag.to_s, current_round.to_s)
        end

        def timestamp
          @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S%4N")[8..-1]
        end

        def reset_timestamp!
          @timestamp = nil
        end
        alias :new_probe! :reset_timestamp!

        def current_period
          period ||
            Time.now.to_i / (BloodContracts.sampling_config[:period] || 1)
        end

        def current_round
          round || timestamp
        end

        def path
          File.join(default_path, session, contract_name.to_s)
        end

        def find_all(path = nil, **kwargs)
          Dir.glob("#{extract_name_from(path, **kwargs)}/*")
        end

        def exists?(path = nil, **kwargs)
          File.exist?("#{extract_name_from(path, **kwargs)}/input")
        end

        def build_with(session, period, round)
          self.class.new(
            session, contract_name, default_path,
            period: period,
            round: round
          )
        end

        def extract_name_from(path = nil, **kwargs)
          session, period, rule, round = parse(path, **kwargs)
          history_name_generator = build_with(session, period, round)
          history_name_generator.call(rule)
        end

        def parse(path = nil, **kwargs)
          path ||= path_from_options(kwargs)
          raise ArgumentError if path.to_s.empty?
          session, contract, period, tag, round = split_path_by_parts!(path)

          if contract.end_with?("*") || contract.match?(contract_name)
            [session, period, tag, round]
          else
            %i(__no_match__) * 4
          end
        end

        private

        def split_path_by_parts!(path)
          path = path.to_s
          path.sub!(default_path, "") if path.start_with?(default_path)
          path_items = path.split("/")
          period, tag, round = path_items.pop(3)
          session = path_items.shift
          contract = path_items.join("/")
          [session, contract, period, tag, round]
        end

        def path_from_options(options)
          [
            options.fetch(:session) { "*" },
            options.fetch(:period)  { "*" },
            options.fetch(:rule)    { "*" },
            options.fetch(:round)   { "*" }
          ].join("/")
        end
      end
    end
  end
end
