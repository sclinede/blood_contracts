require_relative "postgres/contract_switcher.rb"
require_relative "postgres/query.rb"
require_relative "postgres/sampling.rb"

module BloodContracts
  module Storages
    class Postgres < Base
      option :root, default: -> { session }

      def query
        @query ||= Query.build(self)
      end

      include ContractSwitcher
      include Sampling
    end
  end
end
