require_relative "sample"

module BloodContracts
  module Samplers
    class Utils
      extend Dry::Initializer

      param :session
      param :contract_name

      def path
        File.join(default_path, session.to_s, contract_name.to_s)
      end

      # FIXME: работа с FS
      def find_all(path = nil, **kwargs)
        Dir.glob("#{extract_name_from(path, **kwargs)}/*")
      end

      # FIXME: работа с FS
      def exists?(path = nil, **kwargs)
        File.exist?("#{extract_name_from(path, **kwargs)}/input")
      end

      def extract_name_from(path = nil, **kwargs)
        session, period, rule, round = parse(path, **kwargs)
        build_sample(session, period, round).name(rule)
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

      PATH_REGEXP_RULES =
        "(?<session>[#{Nanoid::SAFE_ALPHABET}\\*]+)/"\
        "(?<contract>[\\w/\\*]+)/"\
        "(?<period>[\\d\\*]+)/"\
        "(?<rule>[\\w/\\*]+)/"\
        "(?<round>[\\d\\*]+)".freeze

      PATH_REGEXP = /#{PATH_REGEXP_RULES}/

      # FIXME: нужен лучший алгоритм разделения пути на куски
      # :session/:contract/:period/:rule/:round
      def split_path_by_parts!(path)
        path = path.to_s
        path.sub!(default_path, "") if path.start_with?(default_path)
        path.match(PATH_REGEXP).to_a[1..-1]
      end

      def path_from_options(options)
        [
          options.fetch(:session)  { "*" },
          options.fetch(:contract) { "*" },
          options.fetch(:period)   { "*" },
          options.fetch(:rule)     { "*" },
          options.fetch(:round)    { "*" }
        ].join("/")
      end

      def default_path
        @default_path ||= File.join(root, samples_folder)
      end

      def samples_folder
        BloodContracts.sampling_config.dig(:storage, :samples_folder).to_s
      end

      def root
        BloodContracts.sampling_config.dig(:storage, :root) || "/"
      end

      def build_sample(session, period, round)
        path = File.join(default_path, session.to_s, contract_name.to_s)
        BloodContracts::Samplers::Sample.new(
          path, contract_name, period: period, round: round
        )
      end
    end
  end
end
