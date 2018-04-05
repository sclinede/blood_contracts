require_relative "./samples/name_generator.rb"

module BloodContracts
  module Storages
    class PostgresBackend < BaseBackend
      option :root, default: -> { name }
      alias :contract :example_name
      alias :session :name

      class << self
        def reset_connection!
          @connection = nil
        end

        def connection
          return @connection unless @connection.nil?
          raise "'pg' gem was not required" unless defined?(PG)

          if (connection = BloodContracts.storage_config[:connection])
            @connection = connection.call
          elsif (database_url = BloodContracts.storage_config[:database_url])
            @connection = PG.connect(database_url)
          else
            raise ArgumentError, "Postgres connection not configured!"
          end

          @connection
        end

        def config_table_name
          @config_table_name ||=
            BloodContracts.storage_config.fetch(:config_table_name)
        end

        def table_name
          @table_name ||=
            BloodContracts.storage_config.fetch(:samples_table_name)
        end
      end

      def drop_table!
        connection.exec <<~SQL
          DROP TABLE IF EXISTS #{config_table_name};
          DROP TABLE IF EXISTS #{table_name};
        SQL
      end

      def create_table!
        connection.exec(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{config_table_name}
          AS SELECT false as enabled, ARRAY[]::text[] as enabled_contracts;

          CREATE TABLE IF NOT EXISTS #{table_name} (
            created_at timestamp DEFAULT current_timestamp,

            contract text,
            session text,
            rule text,
            round bigint,
            period bigint,

            input text,
            output text,
            input_dump text,
            output_dump text,
            meta_dump text,
            error_dump text,
            CONSTRAINT uniq_#{table_name}_name
            UNIQUE(contract, session, period, rule, round)
          );
        SQL
      end
      alias :init :create_table!

      def_delegators :"self.class",
                     :connection, :table_name, :config_table_name,
                     :reset_connection!
      def_delegators :name_generator,
                     :extract_name_from, :path, :parse, :current_period,
                     :current_round

      def disable_contract!(contract_name = contract)
        escaped_contract_name = connection.escape_string(contract_name.to_s)

        connection.exec(<<~SQL)
          UPDATE #{config_table_name}
          SET enabled_contracts =
              array_remove(enabled_contracts, '#{escaped_contract_name}'::text)
        SQL
      end

      def enable_contract!(contract_name = contract)
        escaped_contract_name = connection.escape_string(contract_name.to_s)

        connection.exec(<<~SQL)
          UPDATE #{config_table_name}
          SET enabled_contracts =
              enabled_contracts || '#{escaped_contract_name}'::text
        SQL
      end

      def enable_contracts_global!
        connection.exec(<<~SQL)
          UPDATE #{config_table_name} SET enabled = true;
        SQL
      end

      def disable_contracts_global!
        connection.exec(<<~SQL)
          UPDATE #{config_table_name} SET enabled = false;
        SQL
      end

      def contract_enabled?(contract_name = contract)
        escaped_contract_name = connection.escape_string(contract_name.to_s)

        !!connection.exec(<<-SQL).first.to_h["enabled"]
          SELECT true as enabled FROM #{config_table_name}
          WHERE enabled
          OR enabled_contracts @> ARRAY['#{escaped_contract_name}']::text[]
        SQL
      end

      def name_generator
        @name_generator ||= Samples::NameGenerator.new(name, example_name, "/")
      end

      def suggestion
        "Postgres(#{table_name}):#{path}/*/*"
      end

      def unexpected_suggestion
        "Postgres(#{table_name}):#{path}/#{Storage::UNDEFINED_RULE}/*"
      end

      def find_all_samples(path = nil, session: '*', period: '*', rule: '*', round: '*')
        path ||= [session, contract, period, rule, round].join('/')
        match = parse(path)
        session, period, rule, round = match.map { |v| v.sub("*", ".*") }
        connection.exec(<<-SQL).to_a.map { |row| row["name"] }
          SELECT '/' || session || '/' || contract || '/' || period || '/' ||
                 rule || '/' || round as name
          FROM #{table_name}
          WHERE contract ~ '#{contract}'
          AND session ~ '#{connection.escape_string(session)}'
          AND period::text ~ '#{period}'
          AND round::text ~ '#{round}'
          AND rule ~ '#{connection.escape_string(rule)}';
        SQL
      end

      def samples_count(rule)
        connection.exec(<<-SQL).first["count"].to_i
          SELECT COUNT(1) FROM #{table_name}
          WHERE contract ~ '#{contract}'
          AND period::text ~ '#{current_period}'
          AND rule = '#{connection.escape_string(rule)}';
        SQL
      end

      def find_sample(path = nil, session: '*', period: '*', rule: '*', round: '*')
        path ||= [session, contract, period, rule, round].join('/')
        match = parse(path)
        session, period, rule, round = match.map { |v| v.sub("*", ".*") }
        connection.exec(<<-SQL).first.to_h["name"]
          SELECT '/' || session || '/' || contract || '/' || period || '/' ||
                 rule || '/' || round as name
          FROM #{table_name}
          WHERE contract ~ '#{contract}'
          AND session ~ '#{connection.escape_string(session)}'
          AND period::text ~ '#{period}'
          AND round::text ~ '#{round}'
          AND rule ~ '#{connection.escape_string(rule)}'
          LIMIT 1;
        SQL
      end

      def sample_exists?(path = nil, **kwargs)
        find_sample(path, **kwargs).present?
      end

      class SampleNotFound < StandardError; end

      def load_sample_chunk(dump_type, path = nil, **kwargs)
        raise SampleNotFound unless (found_sample = find_sample(path, **kwargs))
        session, period, rule, round = parse(found_sample)
        send("#{dump_type}_serializer")[:load].call(
          connection.exec(<<-SQL).first.to_h.fetch("dump")
            SELECT #{dump_type}_dump as dump FROM #{table_name}
            WHERE contract ~ '#{contract}'
            AND session = '#{connection.escape_string(session)}'
            AND period = '#{period}'
            AND round = '#{round}'
            AND rule = '#{connection.escape_string(rule)}';
          SQL
        )
      end

      def write(*)
        connection.escape_string(super)
      end

      def describe_sample(rule, round_data, context)
        name_generator.reset_timestamp!
        reset_connection!
        connection.exec(<<-SQL)
          INSERT INTO #{table_name}
            (contract, session, period, round, rule, input, output)
          VALUES (
            '#{contract}',
            '#{session}',
            '#{current_period}',
            '#{current_round}',
            '#{rule}',
            '#{write(input_writer, context, round_data)}',
            '#{write(output_writer, context, round_data)}'
          );
        SQL
      end

      def serialize_sample_chunk(chunk, rule, round_data, context)
        return unless (dump_proc = send("#{chunk}_serializer")[:dump])
        data = round_data.send(chunk)
        reset_connection!
        connection.exec(<<-SQL)
          UPDATE #{table_name}
          SET #{chunk}_dump = '#{write(dump_proc, context, data)}'
          WHERE contract = '#{contract}'
          AND session = '#{connection.escape_string(session)}'
          AND period = '#{current_period}'
          AND round = '#{current_round}'
          AND rule = '#{connection.escape_string(rule.to_s)}';
        SQL
      end
    end
  end
end
