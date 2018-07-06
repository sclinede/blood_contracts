module BloodContracts
  module Storages
    class File < Base
      class Sampling < Base::Sampling
        attr_reader :session, :contract_name, :sampler
        def initialize(session, contract_name, sampler)
          @session = session
          @contract_name = contract_name
          @sampler = sampler
        end

        def find(path = nil, **kwargs)
          find_all(path, **kwargs).first
        end

        def count(rule)
          find_all(
            session: session,
            contract: contract_name,
            period: sampler.sample.current_period,
            rule: rule
          ).count
        end

        def exists?(sample_name)
          sampler.utils.exists?(sample_name)
        end

        def delete_all(path = nil, **kwargs)
          files = sampler.utils.find_all(path, **kwargs)
          FileUtils.rm_r(files)
        end

        def find_all(path = nil, **kwargs)
          files = sampler.utils.find_all(path, **kwargs)
          files.select { |f| f.end_with?("/output") }
               .map { |f| f.chomp("/output") }
        end

        def load_chunk(chunk_name, path = nil, **kwargs)
          sample_path = find(path, **kwargs)
          sampler.send("#{chunk_name}_serializer")[:load].call(
            ::File.read("#{sample_path}/#{chunk_name}.dump")
          )
        end

        def load_preview(chunk_name, path = nil, **kwargs)
          sample_path = find(path, **kwargs)
          ::File.read("#{sample_path}/#{chunk_name}")
        end

        def preview(rule, round, context)
          name = sampler.sample.name(rule)
          ::FileUtils.mkdir_p(name)
          ::File.open("#{name}/input", "w+") do |f|
            f << write(sampler.input_previewer, context, round)
          end
          ::File.open("#{name}/output", "w+") do |f|
            f << write(sampler.output_previewer, context, round)
          end
        end

        def serialize_chunk(chunk, rule, round_data, context)
          return unless (dump_proc = sampler.send("#{chunk}_serializer")[:dump])
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
