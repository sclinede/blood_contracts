module BloodContracts
  class Storage
    extend Dry::Initializer

    # Split date and time, for more comfortable Dirs navigation
    option :start_time, default: -> { Time.current.to_s(:number) }
    option :root,
           default: -> { Rails.root.join("tmp/contract_tests/#{start_time}/") }
    option :stats, default: -> { Hash.new(0) }
    option :input_writer
    option :output_writer

    attr_reader :root, :stats

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
      return data.to_s unless writer
      writer = context.method(writer) if context && writer.respond_to?(:to_sym)
      writer.call(input, output)
    end

    # Quick open: `vim -O tmp/contract_tests/<tstamp>/<tag>/<tstamp>.*`
    def save_run(input:, output:, rules:, context:)
      Array(rules).each do |rule_name|
        stats[rule_name] += 1
        run_name = run_name(rule_name)

        # Write to HTML
        input_fname = "#{run_name}.input"
        output_fname = "#{run_name}.output"
        File.open(input_fname, "w+") do |f|
          f << write(input_writer, context, input, output)
        end
        File.open(output_fname, "w+") do |f|
          f << write(output_writer, context, input, output)
        end
      end
    end
  end
end
