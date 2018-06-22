module BloodContracts
  module Storages
    class Postgres < Base
      class Sampling < Base::Sampling
        attr_reader :query
        def initialize(query, sampler)
          @query = query
          @sampler = sampler
        end

        def find_all(path = nil, **kwargs)
          session, period, rule, round = parse(path, **kwargs).map do |v|
            v.sub("*", ".*")
          end
          query.find_all_samples(session, period, rule, round)
        end

        def count(rule)
          query.samples_count(rule)
        end

        def find(path = nil, **kwargs)
          session, period, rule, round = parse(path, **kwargs).map do |v|
            v.to_s.sub("*", ".*")
          end
          query.find_sample(session, period, rule, round)
        end

        def exists?(path = nil, **kwargs)
          find(path, **kwargs).present?
        end

        class SampleNotFound < StandardError; end

        def load_chunk(chunk, path = nil, **kwargs)
          raise SampleNotFound unless (name = find(path, **kwargs))
          session, period, rule, round = parse(name)
          send("#{chunk}_serializer")[:load].call(
            query.load_sample_chunk(session, period, rule, round, chunk)
          )
        end

        def load_preview(_chunk_name, path = nil, **kwargs)
          raise SampleNotFound unless (name = find(path, **kwargs))
          session, period, rule, round = parse(name)
          query.load_sample_preview(session, period, rule, round, chunk)
        end

        def preview(rule, round_data, context)
          query.execute(
            :insert_sample,
            sampling_period_name: sample.current_period,
            round_name: sample.current_round,
            rule_name: rule,
            input: write(input_previewer, context, round_data),
            output: write(output_previewer, context, round_data)
          )
        end

        def serialize_chunk(chunk, rule, round_data, context)
          return unless (dump_proc = send("#{chunk}_serializer")[:dump])
          data = round_data.send(chunk)
          query.execute(
            :serialize_sample_chunk,
            sampling_period_name: sample.current_period,
            round_name: sample.current_round,
            rule_name: rule,
            chunk_name: chunk,
            data: write(dump_proc, context, data)
          )
        end

        private

        def sample
          sampler.sample
        end

        def parse(*args, **kwargs)
          sampler.utils.parse(*args, **kwargs)
        end
      end
    end
  end
end
