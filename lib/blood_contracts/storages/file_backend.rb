require_relative "./samples/name_generator.rb"

module BloodContracts
  module Storages
    class FileBackend < BaseBackend
      alias :contract :example_name
      alias :session :name
      def init
        FileUtils.mkdir_p(File.join("./tmp/blood_contracts/", session))
      end

      def name_generator
        @name_generator ||= Samples::NameGenerator.new(
          session,
          contract,
          "./tmp/blood_contracts/"
        )
      end

      def suggestion
        "#{name_generator.path}/*/*"
      end

      def unexpected_suggestion
        "#{name_generator.path}/#{name_generator.current_period}"\
        "/#{Storage::UNDEFINED_RULE}/*"
      end

      def samples_count(tag)
        find_all_samples("*/*/#{name_generator.current_period}/#{tag}/*").count
      end

      def find_all_samples(path = nil, **kwargs)
        files = name_generator.find_all(path, **kwargs)
        files.select { |f| f.end_with?("/output") }
             .map { |f| f.chomp("/output") }
      end

      def find_sample(path = nil, **kwargs)
        find_all_samples(path, **kwargs).first
      end

      def sample_exists?(sample_name)
        name_generator.exists?(sample_name)
      end

      def load_sample_chunk(chunk_name, path = nil, **kwargs)
        sample_path = find_sample(path, **kwargs)
        send("#{chunk_name}_serializer")[:load].call(
          File.read("#{sample_path}/#{chunk_name}.dump")
        )
      end

      def describe_sample(tag, round, context)
        name_generator.reset_timestamp!
        name = name_generator.call(tag)
        FileUtils.mkdir_p(name)
        File.open("#{name}/input", "w+") do |f|
          f << write(input_writer, context, round)
        end
        File.open("#{name}/output", "w+") do |f|
          f << write(output_writer, context, round)
        end
      end

      def serialize_sample_chunk(chunk, tag, round, context)
        return unless (dump_proc = send("#{chunk}_serializer")[:dump])
        name = name_generator.call(tag)
        data = round.send(chunk)
        File.open("#{name}/#{chunk}.dump", "w+") do |f|
          f << write(dump_proc, context, data)
        end
      end
    end
  end
end
