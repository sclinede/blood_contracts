require_relative "./samples/name_generator.rb"
require_relative "./postgres/contract_switcher.rb"
require_relative "./postgres/query.rb"

module BloodContracts
  module Storages
    class PostgresBackend < BaseBackend
      option :root, default: -> { name }
      alias :contract :example_name
      alias :session :name

      include Postgres::ContractSwitcher

      def query
        @query ||= Postgres::Query.build(self)
      end

      def name_generator
        @name_generator ||= Samples::NameGenerator.new(name, example_name, "/")
      end
      def_delegators :name_generator,
                     :extract_name_from, :path, :parse, :current_period,
                     :current_round

      def suggestion
        "Postgres(#{table_name}):#{path}/*/*"
      end

      def unexpected_suggestion
        "Postgres(#{table_name}):#{path}/#{Storage::UNDEFINED_RULE}/*"
      end

      def find_all_samples(path = nil, **kwargs)
        session, period, rule, round = parse(path, **kwargs).map do |v|
          v.sub("*", ".*")
        end
        query.find_all_samples(session, period, rule, round)
      end

      def samples_count(rule)
        query.samples_count(rule)
      end

      def find_sample(path = nil, **kwargs)
        session, period, rule, round = parse(path, **kwargs).map do |v|
          v.sub("*", ".*")
        end
        query.find_sample(session, period, rule, round)
      end

      def sample_exists?(path = nil, **kwargs)
        find_sample(path, **kwargs).present?
      end

      class SampleNotFound < StandardError; end

      def load_sample_chunk(chunk, path = nil, **kwargs)
        raise SampleNotFound unless (found_sample = find_sample(path, **kwargs))
        session, period, rule, round = parse(found_sample)
        query.load_sample_chunk(session, period, rule, round, chunk)
      end

      def describe_sample(rule, round_data, context)
        name_generator.reset_timestamp!
        query.execute(
          :insert_sample,
          period_name: current_period,
          round_name: current_round,
          rule_name: rule,
          input: write(input_writer, context, round_data),
          output: write(output_writer, context, round_data)
        )
      end

      def serialize_sample_chunk(chunk, rule, round_data, context)
        return unless (dump_proc = send("#{chunk}_serializer")[:dump])
        data = round_data.send(chunk)
        query.execute(
          :serialize_sample_chunk,
          period_name: current_period,
          round_name: current_round,
          rule_name: rule,
          chunk_name: chunk,
          data: write(dump_proc, context, data)
        )
      end
    end
  end
end
