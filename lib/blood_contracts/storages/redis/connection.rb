require "erb"

module BloodContracts
  module Storages
    class Redis < Base
      module Connection
        REDIS_REQUIREMENTS =
          "Please, install and configure 'redis' to use "\
          "Redis DB:\n # Gemfile\n"\
          "gem 'redis', '~> x.x', require: false\n"\
          "gem 'connection_pool', '~> x.x', require: false".freeze

        def redis_loaded?
          return true if defined?(::Redis) && defined?(::ConnectionPool)

          begin
            require "redis"
            require "connection_pool"
          rescue LoadError
            warn REDIS_REQUIREMENTS
          end
        end

        def samples_root
          @samples_root ||= redis_config.fetch(:samples_root)
        end

        def config_root
          @config_root ||= redis_config.fetch(:config_root)
        end

        def current_redis
          return unless ::Redis.respond_to?(:current)
          ::Redis.current
        end

        # FIXME: Do not forget about ConnectionPool, to be safe
        def connection
          return ::Redis.new(url: redis_url) if redis_url
          connection_proc&.call
        end

        # rubocop: disable Metrics/MethodLength
        def connection_proc
          case BloodContracts.storage_config[:connection]
          when ::Redis
            proc { |&b| b.call(redis) }
          when ConnectionPool
            proc { |&b| redis.with { |r| b.call(r) } }
          when Hash
            # ???
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
          @redis_url ||= redis_config.fetch(:redis_url) { ENV["REDIS_URL"] }
        end

        def redis_config
          BloodContracts.storage_config[:redis]
        end
      end
    end
  end
end
