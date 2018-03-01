module BloodContracts
  class Storage
    extend Dry::Initializer

    # Split date and time, for more comfortable Dirs navigation
    option :start_time, default: -> { Date.current.to_s(:number) }
    option :custom_path, optional: true
    option :root, default: -> { Rails.root.join(path) }
    option :stats, default: -> { Hash.new(0) }
    option :input_writer,
           ->(v) { valid_writer(v, fallback: true) }, optional: true
    option :output_writer,
           ->(v) { valid_writer(v, fallback: true) }, optional: true
    option :input_serializer,  ->(v) { valid_serializer(v) }, optional: true
    option :output_serializer, ->(v) { valid_serializer(v) }, optional: true

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

    def default_path
      "./tmp/contract_tests/"
    end

    def path(run_name: start_time)
      File.join(default_path, custom_path.to_s, run_name)
    end

    def valid_writer(writer, fallback: false)
      return method(:default_write_pattern) if !writer && fallback
      raise ArgumentError unless writer.respond_to?(:call) ||
                                 writer.respond_to?(:to_sym)
      writer
    end

    def default_write_pattern(input, output)
      [
        "INPUT:",
        input,
        "\n#{'=' * 90}\n",
        "OUTPUT:",
        output,
      ].map(&:to_s).join("\n")
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

    def timestamp
      Time.current.to_s(:usec)[8..-5]
    end

    def sample_name(tag, run_path: root, sample: timestamp)
      File.join(run_path, tag.to_s, sample)
    end

    def write(writer, context, args)
      writer = context.method(writer) if context && writer.respond_to?(:to_sym)
      writer.call(*args).encode(
        "UTF-8", invalid: :replace, undef: :replace, replace: "?",
      )
    end

    def save_sample(tag, input, output, context)
      FileUtils.mkdir_p File.join(root, tag.to_s)

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

    # Quick open: `vim -O tmp/contract_tests/<tstamp>/<tag>/<tstamp>.*`
    def save_run(input:, output:, rules:, context:)
      Array(rules).each do |rule_name|
        stats[rule_name] += 1

        # TODO: Write to HTML
        save_sample(rule_name, input, output, context)

        serialize_input(rule_name, input, context)
        serialize_output(rule_name, output, context)
      end
    end

    def all_serializers_present?
      [input_serializer, output_serializer].map(&:size).reduce(:+).positive?
    end

    def read_sample(run, tag, sample, dump_type)
      name = sample_name(tag, run_path: path(run_name: run), sample: sample)
      File.read("#{name}.#{dump_type}.dump")
    end

    def sample_exists?(run, tag, sample)
      name = sample_name(tag, run_path: path(run_name: run), sample: sample)
      File.exist?("#{name}.input")
    end

    def find_run(run_pattern)
      return unless all_serializers_present? && run_pattern
      sample_exists?(*run_pattern.split("/"))
    end

    def load_run(run_pattern)
      run, tag, sample = run_pattern.split("/")
      [
        input_serializer[:load].call(read_sample(run, tag, sample, "input")),
        output_serializer[:load].call(read_sample(run, tag, sample, "output")),
      ]
    end
  end
end
