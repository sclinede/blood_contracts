module BloodContracts
  module Storages
    class File < Base
      module Sampling
        def samples_count(rule)
          find_all_samples(
            session: session,
            contract: contract_name,
            period: sampler.current_period,
            rule: rule
          ).count
        end

        def delete_all_samples(path = nil, **kwargs)
          files = sampler.utils.find_all(path, **kwargs)
          FileUtils.rm(files)
        end

        def find_all_samples(path = nil, **kwargs)
          files = sampler.utils.find_all(path, **kwargs)
          files.select { |f| f.end_with?("/output") }
               .map { |f| f.chomp("/output") }
        end

        def find_sample(path = nil, **kwargs)
          find_all_samples(path, **kwargs).first
        end

        def sample_exists?(sample_name)
          sampler.utils.exists?(sample_name)
        end

        def load_sample_preview(chunk_name, path = nil, **kwargs)
          sample_path = find_sample(path, **kwargs)
          ::File.read("#{sample_path}/#{chunk_name}")
        end

        def load_sample_chunk(chunk_name, path = nil, **kwargs)
          sample_path = find_sample(path, **kwargs)
          send("#{chunk_name}_serializer")[:load].call(
            ::File.read("#{sample_path}/#{chunk_name}.dump")
          )
        end

        def describe_sample(rule, round, context)
          name = sampler.sample.name(rule)
          ::FileUtils.mkdir_p(name)
          ::File.open("#{name}/input", "w+") do |f|
            f << write(input_writer, context, round)
          end
          ::File.open("#{name}/output", "w+") do |f|
            f << write(output_writer, context, round)
          end
        end

        def serialize_sample_chunk(chunk, rule, round_data, context)
          return unless (dump_proc = send("#{chunk}_serializer")[:dump])
          name = sampler.sample.name(rule)
          data = round_data.send(chunk)
          ::File.open("#{name}/#{chunk}.dump", "w+") do |f|
            f << write(dump_proc, context, data)
          end
        end
      end
    end
  end
end
