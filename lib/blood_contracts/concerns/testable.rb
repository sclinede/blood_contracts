module BloodContracts
  module Concerns
    module Testable
      def call(*args, **kwargs)
        output, error = nil, nil
        runner.call(args: args, kwargs: kwargs) do |meta|
          begin
            output = yield(meta)
          rescue StandardError => exception
            error = exception
          ensure
            before_runner(meta)
          end
          [output, meta, error]
        end
        raise error if error
        output
      end
    end
  end
end
