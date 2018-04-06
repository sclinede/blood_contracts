module BloodContracts
  module Concerns
    module Testable
      def testing?
        true
      end

      # rubocop:disable Metrics/MethodLength
      def call(*args, **kwargs)
        output = nil
        error = nil
        runner.call(args: args, kwargs: kwargs) do |meta|
          before_call(args: args, kwargs: kwargs, meta: meta)
          begin
            output = yield(meta)
          rescue StandardError => exception
            error = exception
          ensure
            before_runner(
              args: args, kwargs: kwargs,
              output: output, meta: meta, error: error
            )
          end
          [output, meta, error]
        end
        raise error if error
        output
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
