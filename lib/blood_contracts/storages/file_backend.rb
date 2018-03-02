module BloodContracts
  module Storages
    class FileBackend < BaseBackend
      option :start_time, default: -> { Date.current.to_s(:number) }
      option :root, default: -> { Rails.root.join(path) }

      def suggestion
        path
      end

      def default_path
        "./tmp/contract_tests/"
      end

      def timestamp
        @timestamp ||= Time.current.to_s(:usec)[8..-5]
      end

      def reset_timesgamp!
        @timestamp = nil
      end

      def path(run_name: start_time)
        File.join(default_path, example_name.to_s, run_name)
      end

      def sample_name(tag, run_path: root, sample: timestamp)
        File.join(run_path, tag.to_s, sample)
      end

      def sample_exists?(run, tag, sample)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        File.exist?("#{name}.input")
      end

      def read_sample(run, tag, sample, dump_type)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        File.read("#{name}.#{dump_type}.dump")
      end

      def write(writer, cntxt, args)
        writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
        writer.call(*args).encode(
          "UTF-8", invalid: :replace, undef: :replace, replace: "?",
        )
      end

      def save_sample(tag, input, output, context)
        FileUtils.mkdir_p File.join(root, tag.to_s)

        reset_timesgamp!
        name = sample_name(tag)
        File.open("#{name}.input", "w+") do |f|
          f << write(input_writer, context, [input, output])
        end
        File.open("#{name}.output", "w+") do |f|
          f << write(output_writer, context, [input, output])
        end
      end

      def serialize_input(tag, input, context)
        return unless (dump_proc = input_serializer[:dump])
        name = sample_name(tag)
        File.open("#{name}.input.dump", "w+") do |f|
          f << write(dump_proc, context, [input])
        end
      end

      def serialize_output(tag, output, context)
        return unless (dump_proc = output_serializer[:dump])
        name = sample_name(tag)
        File.open("#{name}.output.dump", "w+") do |f|
          f << write(dump_proc, context, [output])
        end
      end
    end
  end
end
