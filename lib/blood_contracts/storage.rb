module BloodContracts
  class Storage
    extend Dry::Initializer

    # Split date and time, for more comfortable Dirs navigation
    option :start_time, default: -> { Time.current.to_s(:number) }
    option :path, default: -> { "./tmp/contract_tests/#{start_time}/" }
    option :root, default: -> { Rails.root.join(path) }
    option :stats, default: -> { Hash.new(0) }
    option :input_writer
    option :output_writer

    UNDEFINED_RULE = :__no_tag_match__

    def input_writer=(writer)
      fail ArgumentError unless writer.respond_to?(:call) ||
                                writer.respond_to?(:to_sym)
      @input_writer = writer
    end

    def output_writer=(writer)
      fail ArgumentError unless writer.respond_to?(:call) ||
                                writer.respond_to?(:to_sym)
      @output_writer = writer
    end

    def run_name(tag)
      run_name = File.join(root, "#{tag}/#{Time.current.to_s(:number)}")
      FileUtils.mkdir_p File.join(root, "#{tag}")
      run_name
    end

    def write(writer, context, input, output)
      return default_write_pattern(input, output) unless writer
      writer = context.method(writer) if context && writer.respond_to?(:to_sym)
      writer.call(input, output)
    end

    def default_write_pattern(input, output)
      [
        "INPUT:",
        input,
        "\n#{'=' * 90}\n",
        "OUTPUT:",
        output
      ].map(&:to_s).join("\n")

    end

    # Quick open: `vim -O tmp/contract_tests/<tstamp>/<tag>/<tstamp>.*`
    def save_run(input:, output:, rules:, context:)
      Array(rules).each do |rule_name|
        stats[rule_name] += 1
        run_name = run_name(rule_name)

        # TODO: Write to HTML
        input_fname = "#{run_name}.input"
        output_fname = "#{run_name}.output"
        File.open(input_fname, "w+") do |f|
          f << write(input_writer, context, input, output).encode(
            'UTF-8', invalid: :replace, undef: :replace, replace: '?'
          )
        end
        File.open(output_fname, "w+") do |f|
          f << write(output_writer, context, input, output).encode(
            'UTF-8', invalid: :replace, undef: :replace, replace: '?'
          )
        end
      end
    end
  end
end
