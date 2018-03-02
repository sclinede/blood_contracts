require_relative "./storages/base_backend.rb"
require_relative "./storages/file_backend.rb"

module BloodContracts
  class Storage
    extend Dry::Initializer
    extend Forwardable

    FileBackend = BloodContracts::Storages::FileBackend

    # Split date and time, for more comfortable Dirs navigation
    option :input_writer,
           ->(v) { valid_writer(v, fallback: true) }, optional: true
    option :output_writer,
           ->(v) { valid_writer(v, fallback: true) }, optional: true
    option :input_serializer,  ->(v) { valid_serializer(v) }, optional: true
    option :output_serializer, ->(v) { valid_serializer(v) }, optional: true
    option :example_name, optional: true
    option :backend, default: -> { FileBackend.new(self, example_name) }

    def_delegators :@backend, :sample_exists?, :read_sample, :suggestion,
                   :serialize_input, :serialize_output, :save_sample

    def input_serializer=(serializer)
      @input_serializer = valid_serializer(serializer)
    end

    def output_serializer=(serializer)
      @output_serializer = valid_serializer(serializer)
    end

    def input_writer=(writer)
      @input_writer = valid_writer(writer, fallback: true)
    end

    def output_writer=(writer)
      @output_writer = valid_writer(writer, fallback: true)
    end

    UNDEFINED_RULE = :__no_tag_match__

    def valid_writer(writer, fallback: false)
      return method(:default_write_pattern) if !writer && fallback
      raise ArgumentError unless writer.respond_to?(:call) ||
                                 writer.respond_to?(:to_sym)
      writer
    end

    def default_write_pattern(input, output)
      "INPUT:\n#{input}\n\n#{'=' * 90}\n\nOUTPUT:\n#{output}"
    end

    def valid_serializer_object?(serializer)
      serializer.respond_to?(:dump) && serializer.respond_to?(:load)
    end

    def valid_serializers_hash?(serializer)
      serializer.respond_to?(:to_hash) &&
        (%i[dump load] - serializer.to_hash.keys).empty?
    end

    def valid_serializer(serializer)
      return default_serializer unless serializer
      return {} unless serializer

      if valid_serializer_object?(serializer)
        {
          load: serializer.method(:load),
          dump: serializer.method(:dump),
        }
      elsif valid_serializers_hash?(serializer)
        serializer.to_hash
      else
        raise "Both #dump and #load methods"\
          " should be defined for serialization"
      end
    end

    def default_serializer
      { load: Oj.method(:load), dump: Oj.method(:dump) }
    end

    # Quick open: `vim -O tmp/contract_tests/<tstamp>/<tag>/<tstamp>.*`
    def save_run(input:, output:, rules:, context:)
      Array(rules).each do |rule_name|
        # TODO: Write to HTML
        save_sample(rule_name, input, output, context)

        serialize_input(rule_name, input, context)
        serialize_output(rule_name, output, context)
      end
    end

    def all_serializers_present?
      [input_serializer, output_serializer].map(&:size).reduce(:+).positive?
    end

    def parse_run_patter(run_pattern)
      run, tag, sample = run_pattern.split("/").last(3)
      sample = File.basename(sample, File.extname(sample))
      [run, tag, sample]
    end

    def load_run(run_pattern)
      run, tag, sample = parse_run_patter(run_pattern)
      [
        input_serializer[:load].call(read_sample(run, tag, sample, "input")),
        output_serializer[:load].call(read_sample(run, tag, sample, "output")),
      ]
    end

    def run_exists?(run_pattern)
      return unless all_serializers_present? && run_pattern
      # ../../<run name>/<rule name>/<sample>
      sample_exists?(*parse_run_patter(run_pattern))
    end
  end
end
