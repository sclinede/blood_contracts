require_relative "./samples/name_generator.rb"
require_relative "./redis/contract_switcher.rb"
require_relative "./redis/query.rb"

module BloodContracts
  module Storages
    class Redis < Base
      option :root, default: -> { session }

      include Redis::ContractSwitcher

      def query
        @query ||= Postgres::Query.build(self)
      end

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
          v.to_s.sub("*", ".*")
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
        send("#{chunk}_serializer")[:load].call(
          query.load_sample_chunk(session, period, rule, round, chunk)
        )
      end

      def describe_sample(rule, round_data, context)
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
