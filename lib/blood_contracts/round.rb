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

    def raw_error
      @data["raw_error"]
    end

    def input_preview
      @data["input_preview"]
    end
    alias :request_preview :input_preview

    def output_preview
      @data["output_preview"]
    end
    alias :response_preview :output_preview

    def initialize(**kwargs)
      kwargs[:raw_error] = kwargs[:error]
      kwargs[:error] = wrap_error(kwargs[:raw_error])
      @data = stringify_keys!(kwargs)
    end

    def to_h
      @data
    end

    def error?
      !error.to_h.empty?
    end

    private

    StringifyExtenstion = Hashie::Extensions::StringifyKeys

    def stringify_keys!(hash)
      return hash unless hash.respond_to?(:to_hash)
      hash.extend(StringifyExtenstion) unless hash.respond_to?(:stringify_keys!)
      hash.keys.each do |k|
        stringify_keys_recursively!(hash[k])
        hash[k.to_s] = hash.delete(k)
      end
      hash
    end

    def stringify_keys_recursively!(object)
      case object
      when self.class
        stringify_keys!(object)
      when ::Array
        object.each do |i|
          stringify_keys_recursively!(i)
        end
      when ::Hash
        stringify_keys!(object)
      end
    end

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
