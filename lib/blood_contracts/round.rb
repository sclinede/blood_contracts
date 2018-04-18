module BloodContracts
  class Round
    extend Forwardable
    attr_reader :data

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
      kwargs[:error] = wrap_error(kwargs[:error])
      @data = Hashie.stringify_keys!(kwargs)
    end

    def to_h
      @data
    end

    def error?
      !error.to_h.empty?
    end

    private

    def wrap_error(exception)
      return {} if exception.to_s.empty?
      return exception.to_h if exception.respond_to?(:to_hash)
      {
        exception.class.to_s => {
          inspect: exception.inspect,
          message: exception.message,
          backtrace: exception.backtrace
        }
      }
    end
  end
end
