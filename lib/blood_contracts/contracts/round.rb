module BloodContracts
  module Contracts
    class Round
      extend Forwardable
      attr_reader :data

      def_delegators :@data, :input, :output, :meta, :error
      alias :request :input
      alias :response :output

      def initialize(**kwargs)
        @data = Hashie::Mash.new(kwargs)
      end

      def with_sub_meta(key)
        sub_round = self.class.new(
          input: input, output: output, meta: {}, error: error,
        )
        result = yield(sub_round)
        data.meta[key] = sub_round.meta
        result
      end
    end
  end
end
