module BloodContracts
  module Contracts
    class Iterator
      extend Dry::Initializer

      param :iterations, ->(v) do
        v = ENV["iterations"] if ENV["iterations"]
        v.to_i.positive? ? v.to_i : 1
      end
      param :time_to_run, ->(v) do
        v = ENV["duration"] if ENV["duration"]
        v.to_f if v.to_f.positive?
      end, optional: true

      def next
        return iterations.times { yield } unless time_to_run

        @iterations = iterations_from_time_to_run { yield }
        [iterations - 1, 0].max.times { yield }
      end

      def count
        @iterations
      end

      protected

      def iterations_from_time_to_run
        time_per_action = Benchmark.measure { yield }
        (time_to_run / time_per_action.real).ceil
      end
    end
  end
end
