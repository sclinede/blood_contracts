require "erb"

module BloodContracts
  module Storages
    class Redis
      class Query
        extend Dry::Initializer
        option :contract_name, optional: true
        option :session_name, optional: true
        option :period_name, optional: true
        option :round_name, optional: true

        class << self
          def build(backend)
            redis_loaded?
            new(
              contract_name: backend.contract_name,
              session_name: backend.session,
              period_name: backend.current_period,
              round_name: backend.current_round
            )
          end

          def redis_loaded?
            return true if defined?(::Redis)

            begin
              require "redis"
            rescue LoadError
              warn(
                "Please, install and configure 'pg' to send notifications:\n" \
                "# Gemfile\n" \
                "gem 'pg', '~> 1.0', require: false"
              )
            end
          end
        end

        def execute(query_name, options = {})
          reset_connection!
          prepare_variables(options)
          connection.exec(sql(query_name))
        end

      def initialize(redis)
        @redis_proc = build_redis_proc(redis)
      end

      def exec(&block)
        @redis_proc.call(&block)
      end

      private


        def contract_enabled(contract_name)
          result = execute(:is_contract_enabled, contract_name: contract_name)
          result.first.to_h["enabled"]
        end

        def load_sample_chunk(*args)
          raise ArgumentError unless args.size.eql?(5)
          options = %i(
            session_name period_name rule_name round_name chunk_name
          ).zip(args)

          execute(:load_sample_chunk, options).first.to_h.fetch("dump")
        end

        def find_sample(session_name, period_name, rule_name, round_name)
          execute(
            :find_all_samples,
            session_name: session_name,
            period_name: period_name,
            rule_name: rule_name,
            round_name: round_name
          ).first.to_h["sample_path"]
        end

        def find_all_samples(session_name, period_name, rule_name, round_name)
          execute(
            :find_all_samples,
            session_name: session_name,
            period_name: period_name,
            rule_name: rule_name,
            round_name: round_name
          ).to_a.map { |row| row["sample_path"] }
        end

        def samples_count(rule_name)
          execute(:count_samples, rule_name: rule_name).first["count"].to_i
        end

        private

        def sql(query_name)
          ERB.new(File.read(file_path(query_name))).result(binding)
        end

        def file_path(query_name)
          File.join(__dir__, "templates", "#{query_name}.sql.erb")
        end

        def samples_table_name
          @samples_table_name ||=
            BloodContracts.storage_config.fetch(:samples_table_name)
        end

        def config_table_name
          @config_table_name ||=
            BloodContracts.storage_config.fetch(:config_table_name)
        end

        def reset_connection!
          @connection = nil
        end

        def connection
          return @connection unless @connection.nil?
          return @connection = pg_connection_proc.call if pg_connection_proc
          return @connection = ::PG.connect(database_url) if database_url

          raise ArgumentError, "Postgres connection not configured!"
        end

        def connection
          return @connection unless @connection.nil?
          return @connection = redis_connection_proc.call if redis_connection_proc
          return @connection = ::Redis.new(redis) if redis_connection_proc

          raise ArgumentError, "Postgres connection not configured!"
        end

        # rubocop: disable Metrics/MethodLength
        def redis_connection_proc
          case BloodContracts.storage_config[:redis_connection]
          when ::Redis
            proc { |&b| b.call(redis) }
          when ConnectionPool
            proc { |&b| redis.with { |r| b.call(r) } }
          when Hash
            build_redis_proc(::Redis.new(redis))
          when Proc
            redis
          else
            raise ArgumentError, \
              "Redis, ConnectionPool, Hash or Proc is required"
          end
        end
        # rubocop: enable Metrics/MethodLength

        def redis_url
          @redis_url ||= BloodContracts.storage_config[:redis_url]
        end

        def prepare_variables(options)
          return if options.empty?
          options.each do |k, v|
            instance_variable_set("@#{k}", v)
          end
        end
      end
    end
  end
end
