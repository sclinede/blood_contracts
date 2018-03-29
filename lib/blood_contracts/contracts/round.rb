module BloodContracts
  module Contracts
    class Round
      extend Forwardable
      attr_reader :data

      def_delegators :@data, :input, :output, :meta, :error

      def input
        @data["input"]
      end
      alias :request :input

      def output
        @data["output"]
      end
      alias :response :output

      def meta
        @data["meta"]
      end

      def error
        @data["error"]
      end

      def initialize(**kwargs)
        @data = ::Hashie::Hash[kwargs].stringify_keys
      end
    end
  end
end
