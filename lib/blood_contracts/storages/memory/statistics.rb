module BloodContracts
  module Storages
    class Memory < Base
      module Statistics

        STATISTICS_ROOT_KEY = "blood_statistics".freeze

        def init
          return if memory_store
          if defined?(::Concurrent::Map)
            BloodContracts.instance_variable_set(:@memory_store, ::Concurrent::Map.new)
          else
            BloodContracts.instance_variable_set(:@memory_store, ::Concurrent::Map.new)
          end
        end

        def storage
          BloodContracts.instance_variable_get(:@memory_store)
        end

        def suggestion
          "#{path}/*/*"
        end

        def unexpected_suggestion
          "#{path}/#{current_period}/#{Storage::UNDEFINED_RULE}/*"
        end

        def increment_statistics(rule, period = current_period)
          prepare_statistics_storage(period)
          # Lock! Lock! Lock!
          storage[STATISTICS_ROOT_KEY][period] += 1
        end

        def prepare_statistics_storage(period)
          return unless storage.dig(*statistcs_key(period)).nil?
          if defined?(::Concurrent::Map)
            storage[STATISTICS_ROOT_KEY][period] = ::Concurrent::Map.new { 0 }
          else
            storage[STATISTICS_ROOT_KEY][period] = ::Hash.new(0)
          end
        end

        def statistcs_key(period = current_period)
          ["#{STATISTICS_ROOT_KEY}-#{contract_name}", period, rule]
        end

        def statistics_per_rule(*rules)
          Hash[
            Array(rules).map do |rule|
              next [rule.to_s, 0] unless File.exists?(stats_path)
              [rule.to_s, samples_count(rule)]
            end
          ]
        end

        def samples_count(rule, period = current_period)
          find_all_samples(period: period, rule: rule).count
        end

        def find_all_samples(path = nil, **kwargs)
          keys = name_generator.find_all(path, **kwargs)
          storage.keys & keys
        end

        def find_sample(path = nil, **kwargs)
          find_all_samples(path, **kwargs).first
        end

        def sample_exists?(sample_name)
          storage.key?(extract_name_from(sample_name))
        end

        def load_sample_chunk(chunk_name, path = nil, **kwargs)
          sample_key = find_sample(path, **kwargs)
          send("#{chunk_name}_serializer")[:load].call(
            storage[sample_key]["#{chunk_name}_dump"]
          )
        end

        def describe_sample(tag, round, context)
          sample_key = name_generator.call(tag)
          storage[sample_key] = {
            "input" => write(input_writer, context, round),
            "output" => write(output_writer, context, round)
          }
        end

        def serialize_sample_chunk(chunk, tag, round, context)
          return unless (dump_proc = send("#{chunk}_serializer")[:dump])
          sample_key = name_generator.call(tag)
          data = round.send(chunk)
          storage[sample_key]["#{chunk}_dump"] = write(dump_proc, context, data)
        end

        # def collect_stats(tag)
        #   stats_file = File.join(stats_path, tag)
        #   File.open("#{stats_path}/input", "a") do |f|
        #     f << "#{name = name_generator.call(tag)}\r\n"
        #   end
        # end
      end
    end
  end
end
