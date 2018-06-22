require "erb"

module BloodContracts
  module Storages
    class Postgres < Base
      class Query
        module Connection
          def pg_loaded?
            return true if defined?(::PG)

            begin
              require "pg"
            rescue LoadError
              warn(
                "Please, install and configure 'pg' to use Postgres DB:\n" \
                "# Gemfile\n" \
                "gem 'pg', '~> 1.0', require: false"
              )
            end
          end

          def samples_table_name
            @samples_table_name ||= postgres_config.fetch(:samples_table_name)
          end

          def config_table_name
            @config_table_name ||= postgres_config.fetch(:config_table_name)
          end

          def reset_connection!
            @connection = nil
          end

          def connection
            return @connection unless @connection.nil?
            return @connection = connection_proc.call if connection_proc
            return @connection = ::PG.connect(database_url) if database_url

            raise ArgumentError, "Postgres connection not configured!"
          end

          def release_connection_proc
            @release_connection_proc ||= postgres_config[:release_connection]
            @release_connection_proc ||= ->(connection) { connection.finish }
          end

          def connection_proc
            @connection_proc ||= postgres_config[:connection]
          end

          def database_url
            @database_url ||= postgres_config.fetch(:database_url) do
              ENV["DATABASE_URL"]
            end
          end

          def postgres_config
            BloodContracts.storage_config[:postgres]
          end
        end
      end
    end
  end
end
