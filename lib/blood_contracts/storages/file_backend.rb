require_relative "./files/name_generator.rb"

module BloodContracts
  module Storages
    class FileBackend < BaseBackend
      def name_generator
        @name_generator ||= Files::NameGenerator.new(
          name,
          example_name,
          "./tmp/blood_contracts/",
        )
      end

      def suggestion
        "#{name_generator.path}/*/*"
      end

      def unexpected_suggestion
        "#{name_generator.path}/#{Storage::UNDEFINED_RULE}/*"
      end

      def samples_count(tag)
        find_all_samples("*/*/#{name_generator.current_period}/#{tag}/*").count
      end

      def find_all_samples(sample_name)
        files = name_generator.find_all(sample_name)
        files.select { |f| f.end_with?(".output") }
             .map { |f| f.chomp(".output") }
      end

      def find_samples(sample_name)
        find_all(sample_name).first
      end

      def sample_exists?(sample_name)
        name_generator.exists?(sample_name)
      end

      def load_sample_chunk(dump_type, sample_name)
        name = name_generator.extract_name_from(sample_name)
        send("#{dump_type}_serializer")[:load].call(
          File.read("#{name}.#{dump_type}.dump"),
        )
      end

      def describe_sample(tag, round, context)
        FileUtils.mkdir_p File.join(name_generator.root, tag.to_s)
        name_generator.reset_timestamp!
        name = name_generator.call(tag)
        File.open("#{name}.input", "w+") do |f|
          f << write(input_writer, context, round)
        end
        File.open("#{name}.output", "w+") do |f|
          f << write(output_writer, context, round)
        end
      end

      def serialize_sample_chunk(chunk, tag, round, context)
        return unless (dump_proc = send("#{type}_serializer")[:dump])
        name = name_generator.call(tag)
        data = round.send(chunk)
        File.open("#{name}.#{type}.dump", "w+") do |f|
          f << write(dump_proc, context, data)
        end
      end
    end
  end
end
