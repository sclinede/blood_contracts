module BloodContracts
  module Storages
    class Postgres < Base
      module Sampling
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
          raise SampleNotFound unless (name = find_sample(path, **kwargs))
          session, period, rule, round = parse(name)
          send("#{chunk}_serializer")[:load].call(
            query.load_sample_chunk(session, period, rule, round, chunk)
          )
        end

        def load_sample_preview(_chunk_name, path = nil, **kwargs)
          raise SampleNotFound unless (name = find_sample(path, **kwargs))
          session, period, rule, round = parse(name)
          query.load_sample_preview(session, period, rule, round, chunk)
        end

        def describe_sample(rule, round_data, context)
          query.execute(
            :insert_sample,
            sampling_period_name: sampler.current_period,
            round_name: sampler.current_round,
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
            sampling_period_name: sampler.current_period,
            round_name: sampler.sample.current_round,
            rule_name: rule,
            chunk_name: chunk,
            data: write(dump_proc, context, data)
          )
        end

        private

        def parse(*args, **kwargs)
          sampler.utils.parse(*args, **kwargs)
        end
      end
    end
  end
end
