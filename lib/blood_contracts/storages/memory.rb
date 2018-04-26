require_relative "memory/statistics"

module BloodContracts
  module Storages
    class Memory < Base
      attr_reader :storage

      def init
        return unless global_store.nil?
        BloodContracts.instance_variable_set(:@memory_store, storage_klass.new)
      end

      def statistics(statistics)
        Statistics.new(self, statistics).tap(&:init)
      end

      def sampling(*)
        raise NotImplementedError
      end

      def switching(*)
        raise NotImplementedError
      end

      def global_store
        BloodContracts.instance_variable_get(:@memory_store)
      end

      def root
        "#{ROOT_KEY}-#{base_storage.contract_name}"
      end

      def storage_klass
        if defined?(::Concurrent::Map)
          ::Concurrent::Map
        else
          ::Hash
        end
      end
    end
  end
end
