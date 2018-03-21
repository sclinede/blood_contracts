module BloodContracts
  module Storages
    class PostgresBackend < BaseBackend
      option :root, default: -> { name }

      class << self
        def connection
          return @connection if defined? @connection
          raise "'pg' gem was not required" unless defined?(PG)
          @connection = PG.connect(
            BloodContracts.config.storage["database_url"]
          )
        end

        def table_name
          @table_name ||= BloodContracts.config.storage["table_name"]
        end

        def create_table
          connection.exec(<<-SQL)
            CREATE TABLE IF NOT EXISTS #{table_name} (
              created_at timestamp DEFAULT current_timestamp,
              name text,
              input text,
              output text,
              input_dump text,
              output_dump text,
              meta_dump text,
              error_dump text,
              CONSTRAINT uniq_#{table_name}_name UNIQUE(name)
            );
          SQL
        end
      end

      def_delegators :"self.class", :connection, :table_name

      def suggestion
        "Postgres(#{table_name}):#{path}/*/*"
      end

      def unexpected_suggestion
        "Postgres(#{table_name}):#{path}/#{Storage::UNDEFINED_RULE}/*"
      end

      def default_path
        "/"
      end

      def timestamp
        @timestamp ||= Time.current.to_s(:usec)[8..-3]
      end

      def reset_timestamp!
        @timestamp = nil
      end

      def parse_sample_name(sample_name)
        sample_name.gsub("*", ".*")
        path_items = sample_name.split("/")
        sample = path_items.pop
        tag = path_items.pop
        path_str = path_items.join("/")
        run_n_example_str = path_str.sub(default_path, "")
        if run_n_example_str.end_with?(".*")
          [
            run_n_example_str.chomp(".*"),
            tag,
            sample,
          ]
        elsif run_n_example_str.end_with?(example_name)
          [
            run_n_example_str.chomp(example_name),
            tag,
            sample,
          ]
        else
          %w(__no_match__ __no_match__ __no_match__)
        end
      end

      def find_all_samples(sample_name)
        run, tag, sample = parse_sample_name(sample_name)
        run_path = path(run_name: run)
        connection.exec <<-SQL
          SELECT name FROM #{table_name}
          WHERE name ~ '#{run_path}/#{tag}/#{sample}%';
        SQL
      end

      def path(run_name: name)
        File.join(default_path, run_name, example_name.to_s)
      end

      def sample_name(tag, run_path: root, sample: timestamp)
        File.join(run_path, tag.to_s, sample)
      end

      def sample_exists?(sample_name)
        run, tag, sample = parse_sample_name(sample_name)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        connection.exec(<<-SQL).size.positive?
          SELECT 1 FROM #{table_name} WHERE name LIKE #{name};
        SQL
      end

      def load_sample_chunk(dump_type, sample_name)
        run, tag, sample = parse_sample_name(sample_name)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        send("#{dump_type}_serializer")[:load].call(
          connection.exec(<<-SQL).first
            SELECT #{dump_type} FROM #{table_name} WHERE name = #{name};
          SQL
        )
      end

      def write(writer, cntxt, round)
        writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
        connection.escape_string(
          writer.call(round).encode(
            "UTF-8", invalid: :replace, undef: :replace, replace: "?",
          )
        )
      end

      def describe_sample(tag, round, context)
        reset_timestamp!
        name = sample_name(tag)
        connection.exec(<<-SQL)
          INSERT INTO #{table_name} (name, input, output)
          VALUES (
            '#{name}',
            '#{write(input_writer, context, round)}',
            '#{write(output_writer, context, round)}'
          )
        SQL
      end

      def serialize_sample_chunk(chunk, tag, round, context)
        return unless (dump_proc = send("#{chunk}_serializer")[:dump])
        name = sample_name(tag)
        data = round.send(chunk)
        connection.exec(<<-SQL)
          UPDATE #{table_name}
          SET #{chunk}_dump = '#{write(dump_proc, context, data)}'
          WHERE name = '#{name}';
        SQL
      end
    end
  end
end
