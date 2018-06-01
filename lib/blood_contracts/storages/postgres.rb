require_relative "postgres/switching.rb"
require_relative "postgres/query.rb"
require_relative "postgres/sampling.rb"

module BloodContracts
  module Storages
    class Postgres < Base
      option :root, default: -> { session }

      def switching(_switcher)
        Switching.new(query)
      end

      def sampling(sampler)
        Sampling.new(query, sampler)
      end

      def drop_tables!
        query.execute(:drop_tables)
      end

      def create_tables!
        query.execute(:create_tables)
      end
      alias :init :create_tables!

      def query
        @query ||= Query.new(
          contract_name: contract_name,
          session_name: session
        )
      end
    end
  end
end
