require "erb"

module BloodContracts
  module Storages
    class Postgres < Base
      class Query
        module Connection
          def redis_loaded?
            return true if defined?(::Redis)

            begin
              require "pg"
            rescue LoadError
              warn(
                "Please, install and configure 'redis' to use Redis DB:\n" \
                "# Gemfile\n" \
                "gem 'redis', '~> x.x', require: false"
              )
            end
          end

          def samples_root
            @samples_root ||= redis_config.fetch(:samples_root)
          end

          def config_root
            @config_root ||= redis_config.fetch(:config_root)
          end

          def reset_connection!
            @connection = nil
          end

          def connection
            return @connection unless @connection.nil?
            return @connection = connection_proc.call if connection_proc
            return @connection = ::Redis.new(redis_url) if redis_url

            raise ArgumentError, "Redis connection not configured!"
          end

          # rubocop: disable Metrics/MethodLength
          def connection_proc
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

          def redis_config
            BloodContracts.storage_config[:redis].to_h
          end
        end
      end
    end
  end
end
